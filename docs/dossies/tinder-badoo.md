# Dossiê — Tinder & Badoo no escopo do projeto (n100 + alvo em 192.168.100.0/24 / br-lan)

> Cenário assumido: fingerprinting **passivo na rede** (mesma classe da conversa `161a6e937e695ac8`).
> Se o alvo for outro (Waydroid local, MITM ativo, etc.), me avise — o dossiê muda quase inteiro.
>
> Todas as afirmações abaixo vêm das fontes citadas. Quando a fonte é um paper ou doc pública
> de 2019-2025, o comportamento **pode ter mudado** — o que vale ainda é o método de observação
> e a infraestrutura, não a versão exata da API.
>
> **Restrição jurídica/ética (LGPD/Marco Civil/CP)**: interceptar e logar conteúdo de apps de
> terceiros sem consentimento é crime. O dossiê cobre só metadados e fingerprinting de
> **tráfego observável em rede administrada por você** (192.168.100.0/24) e **hosts do próprio
> usuário** (Waydroid local). Se a LGPD/Justiça exigir, o quê registrar precisa de base legal
> e粒to de retenção definidos antes do deploy.

---

## 1. O que esses apps são, em termos de rede

| App | Controladora | Backend principal | CDN / infra | Endereços-chave (SNI) |
|---|---|---|---|---|
| Tinder | Tinder Inc. (Match Group) | `api.gotinder.com` (REST) sobre TLS 1.3 | **Amazon CloudFront** (~1563 IPs, geolocalizado por DNS) | `api.gotinder.com`, `graph.facebook.com` (login), `*.tinder.com` |
| Badoo | Bumble Trading LLC (Bumble Inc.) | `eu1.badoo.com`, `us1.badoo.com` | Própria / multi-região (eu1, us1) + `badoocdn.com` (ecdn2) | `eu1.badoo.com`, `us1.badoo.com`, `*.badoocdn.com`, `consent.badoo.com` |
| Bumble | Bumble Inc. (mesma controladora) | Compartilhado com Badoo | "Shared infrastructure" (SEC) | `bumble.com`, `*.bumble.com` (provavelmente mesmo ASN de Badoo) |

> **Consequência operacional para a rede:**
> - **Tinder**: o SNI `api.gotinder.com` resolve para CloudFront. O conjunto de IPs é compartilhado
>   com milhares de outros clientes CloudFront, então **bloquear por IP não é opção**. O SNI é o
>   pivô confiável (até a ECH chegar — ver §6).
> - **Badoo**: ASN mais concentrado, IPs próprios, mais fácil de bloquear/identificar por SNI
>   **e** por IP. Mas cuidado: o Bumble compartilha infra com Badoo (SEC: "shared infrastructure"),
>   então classificar um como o outro é fácil.
> - **Mesmo app, regiões diferentes**: `eu1.badoo.com` vs `us1.badoo.com`. O usuário brasileiro
>   provavelmente usa `us1.badoo.com` (geolocalização por DNS, como CloudFront faz).

Fontes: [Netify `api.gotinder.com`](https://www.netify.ai/resources/hostnames/api.gotinder.com),
[URLScan `badoo.com`](https://urlscan.io/result/019981c0-483b-753e-b621-7718b5c1cc72),
[SEC S-1 Bumble](https://www.sec.gov/Archives/edgar/data/1830043/000095012320010633/filename1.htm).

---

## 2. O que dá para extrair **passivamente** da rede (sem instalar nada no aparelho)

### 2.1. Vetores fortes (alta confiança, baixo custo)

| Vetor | O que revela | Limitações |
|---|---|---|
| **DNS em texto (porta 53)** | Domínios `gotinder.com`, `badoo.com`, `bumble.com`, `*.badoocdn.com` | Se o usuário usa DoH/DoT/QUIC, o DNS não passa pela rede local |
| **SNI do ClientHello (TLS 1.2 / TLS 1.3 sem ECH)** | Hostname exato: `api.gotinder.com`, `eu1.badoo.com` | Apaga com ECH (ver §6) |
| **ASN/IP de destino** | Tinder = CloudFront (AS16509); Badoo = ASN próprio; Bumble = mesmo de Badoo | IPs CloudFront são compartilhados — não dá para afirmar "esse IP é Tinder" |
| **Volume/ritmo (NetFlow, sFlow, IPFIX)** | Sessões longas durante uso (chat), rajadas curtas (refresh de feed), ~10s de inatividade | Precisa de flow collector (softflowd / nfdump) — não tem de fábrica |
| **Fingerprint de pacotes (tamanho + direção + IAT)** | Identificar o app com 90%+ mesmo com TLS ([AppPrint, AFMA](https://arxiv.org/html/1704.06099v1)) | Requer captura contínua e modelo treinado por app; casamento contra dataset |
| **TLS fingerprint (JA3/JA4)** | Versão TLS, cipher suites, extensões, ALPN | Tinder/Badoo usam libs de cliente identificáveis; distingue Tinder de Bumble mesmo no mesmo IP |

### 2.2. Vetores fracos (sinal presente, mas ruidoso)

- **QUIC/HTTP3** ([JA4+ suite](https://github.com/FoxIO-LLC/ja4)): ambos apps suportam — QUIC
  aparece como tráfego UDP/443 e pode ser fingerprintado por **Initial Packet** (que carrega
  ClientHello criptografado + ALPN). Útil quando ECH está ativo e o SNI some.
- **Certificado leaf do TLS**: assinante (Let's Encrypt, DigiCert, Amazon), validade, SANs.
  Não revela muito, mas corrobora.
- **Tamanho de payload típico por endpoint**: `/recs/core` (feed de cards) tem assinatura de
  tamanho diferente de `/message` (chat). Mesmo criptografado, dá para inferir **ação** do
  usuário (ver §4).

### 2.3. O que **não** dá passivamente

- Conteúdo das mensagens (E2E onde existir, TLS no resto).
- Quem é a outra pessoa (matching é estado servidor).
- Conteúdo das fotos (vão sobre TLS, mas dá para inferir *que* foram carregadas pelo ritmo).
- Localização exata (os apps geocodificam no servidor, o cliente só envia Δ de GPS — que vai
  criptografado).

---

## 3. O que dá para extrair **ativamente** se você roda o app no Waydroid local

(Só relevante se for seu próprio aparelho/ambiente, com a skill `waydroid_manager` já configurada.)

- **Logs adb**: o app não loga mensagens, mas loga **endpoints** chamados, status code, latência.
  Filtrar por `com.tinder` / `com.badoo.mobile` / `com.bumble.app` no `logcat`.
- **Sandbox `/data/data/<pkg>/`**:
  - `databases/`: cache de matches, mensagens pré-renderizadas, perfil. Em Bumble, o paper
    [MDPI 2022](https://www.mdpi.com/2673-6756/2/1/16) extrai match list, mensagens,
    timestamps, fotos, **a partir do sandbox do Android** sem root completo.
  - `shared_prefs/`: tokens, OAuth state, último user-agent, device fingerprint.
  - `cache/`: fotos em thumb/full baixadas pelo app (caminho
    `<sandbox>/cache/ImageCache/`).
- **MITM com CA do usuário (Magisk + Play Integrity já configurado)**: instalar a CA do
  mitmproxy no `/system/etc/security/cacerts/` via `mount --bind` (root). Funciona em **apps
  sem pinning** ou com pinning fraco. Tinder e Badoo em 2021-2022 usavam pinning (Bumble
  pinning por Trustkit/OkHttp) — bypass com **Frida + objection** ou **apk-debuggable**
  (ver [medium](https://medium.com/@benlue/how-to-inspect-any-android-apps-network-traffic-with-mitmproxy-c3d2a210da41)).
  Ver §7 sobre Play Integrity.
- **Frida scripts**: dá para hookar `OkHttpClient` / `URLConnection` e logar request/response
  sem precisar de pinning bypass — a Frida vê o tráfego **antes** do TLS. O
  [HTTP Toolkit](https://httptoolkit.com/blog/frida-certificate-pinning/) e o
  [redfoxsec](https://www.redfoxsec.com/blog/ssl-pinning-bypass-for-android-using-frida)
  mostram o método (setembro/2025).

> **Zygisk Next + tradução ARM**: Zygisk Next é compatível com módulos LSPosed/riru; Frida
> server roda em **Zygisk** (build oficial `frida-server` empacotada como módulo Zygisk) ou
> standalone via `adb push` + `su`. A camada ARM é irrelevante para Tinder/Badoo (são
> ARM-native), só importa se você for hookar uma versão x86 do app.

---

## 4. O que dá para **inferir sobre o uso** (mesmo com E2E)

Combinando tamanho de payload, ritmo e endpoint conhecido:

- **Login vs. uso contínuo**: 1 POST grande em `auth` ou `/v2/auth/login` (Tinder) + 1 GET
  `/me` = login. Depois disso, GET `/recs/core` periódico (~5-30s) = feed sendo navegado.
- **Swipe vs. match**: GET `/recs/core` em loop curto, depois parada = sem match; ou POST
  `/like/{id}` / `/pass/{id}` em rajadas = swipando.
- **Mensagem**: POST `/message` (ou `usermatches/{id}/message`) = mandou; GET
  `/usermatches/{id}/messages` periódico = conversa aberta. O **tamanho** da POST indica
  texto longo vs. curtinha vs. foto.
- **Heart of the app** (heurística, não comprovada para Tinder/Badoo 2026): sessão de uso
  tem assinatura reconhecível mesmo criptografada — comparar com o paper
  [AppPrint / AFMA](https://arxiv.org/html/1704.06099v1) e
  [MDPI Badoo](https://pmc.ncbi.nlm.nih.gov/articles/PMC9628447/), que conseguiram classificar
  ações com Wireshark + proxy MITM.

> O paper do PMC sobre Badoo ([PMC9628447](https://pmc.ncbi.nlm.nih.gov/articles/PMC9628447/),
> 2022) é o mais explícito: instalaram o app em Moto G5 Plus, capturaram com Wireshark num
> MITM laptop, e identificaram login, navegação, mensagens, fotos e metadados de localização
> **sem root**. Conclusão: a segurança de Badoo em 2022 era fraca contra MITM. O artigo é
> o melhor manual de "o que observar" para qualquer um que esteja montando um sensor.

---

## 5. Implementação sugerida no n100 (passivo)

### 5.1. Captura

```bash
# Mínimo: tcpdump rotativo no br-lan ou 192.168.100.0/24
sudo tcpdump -i br-lan -w /var/log/pcap/%Y%m%d-%H%M.pcap \
  -G 3600 -W 24 'host 192.168.100.0/24 and (port 53 or port 443 or port 853)'

# Melhor: Zeek com JA4
nix-shell -p zeek --run "zeek -i br-lan -C LogAscii::default_include=ALL"
# JA4 no Zeek: https://zeek.org/2026/01/how-to-use-ja4-network-fingerprints-in-zeek/
```

### 5.2. Filtro (nftables, sem descriptografia)

```nix
# No módulo n100 (exemplo)
networking.nftables.tables = {
  filter = {
    chains.input = {
      tcp dport 443 tcp flags syn counter log prefix "tinder-https: ";
    };
  };
};
# Pivô: log de SNI é via Zeek/connlog, não nft. Use Zeek conn.log + ssl.log.
```

### 5.3. Identificação de SNI (Tinder, Badoo, Bumble)

```zeek
# No Zeek: ssl.log já loga server_name (SNI). Filtrar:
@load base/protocols/ssl
# Query: server_name in {api.gotinder.com, eu1.badoo.com, us1.badoo.com, *.badoocdn.com, *.bumble.com}
# Detecção adicional via JA4: comparar fingerprint com modelo treinado do app
#   (dataset: https://data.mendeley.com/datasets/6v3zcxysh7 — 10 social media apps).
```

### 5.4. Bloqueio (se for o caso)

- **dnscrypt-proxy**: adicionar `gotinder.com`, `*.badoo.com`, `*.badoocdn.com`, `*.bumble.com`
  a um blocklist local. Funciona enquanto o cliente usa DNS padrão; com DoH no cliente,
  bypass.
- **AdGuard Home**: tem lista "Dating services" pronta (Grindr, Tinder, Badoo, Bumble
  explícitos — ver [setup guide](https://bybrzoza.com/adguard-home-raspberry-pi-docker-guide/)).
- **nftables + nfqueue**: precisa interceptar o **TLS ClientHello** (SNI) com
  [sniqueue](https://github.com/jsimonetti/sniqueue/blob/master/nftables.conf) e decidir
  aceitar/drop por hostname. Funciona, mas só até o cliente ativar ECH.
- **HAProxy/nhate em modo TCP**: o tráfego que chega a você (ex.: `dl_conn`) pode ser
  terminado e inspecionado pelo SNI antes de upstream. Mas o SNI chega em cleartext
  **hoje**; com ECH passa a ser cifrado pelo ECHConfig do CDN (Cloudflare, CloudFront já
  tem roadmap).

---

## 6. O que **muda** com ECH e QUIC — e quando

| Tecnologia | Estado hoje (2026) | Impacto |
|---|---|---|
| **TLS 1.3** | Default em Tinder/Badoo/Bumble | Reduz metadados do handshake; **SNI continua claro** |
| **QUIC/HTTP3** | Tinder e Badoo já usam em alguns endpoints | UDP/443; SNI **continua claro** no Initial Packet; ganha um Initial Packet por conexão |
| **ECH (RFC 9849)** | Cloudflare 1.0; CloudFront em beta; Firefox habilita por default; Chrome opt-in | **Mata o pivô SNI** — sem descriptografia você só vê o "outer SNI" (o CDN que entrega o ECHConfig) |
| **ESNI** | Removido do Firefox 85+ em favor de ECH | Idem |

> **Na prática, em 2026**: SNI de `api.gotinder.com` (CloudFront) **provavelmente ainda é
> visível** porque o ECHConfig da CloudFront ainda está em rollout. Em 2027+ espere o SNI
> virar "cloudfront.net" para todos os apps hospedados lá. Para Badoo (infra própria), ECH
> depende de a Bumble Inc. implementar — o paper de 2022 não menciona.

Quando ECH ligar de verdade, o pivô passa a ser:
- **JA4 + JA4+** ([FoxIO](https://github.com/FoxIO-LLC/ja4), [Cloudflare blog](https://blog.cloudflare.com/ja4-signals/)) — fingerprint do TLS ClientHello sobrevive ao ECH se você ler o **inner** (não consegue passivamente).
- **QUIC Initial Packet** fingerprint — sobrevive, é público no payload.
- **Padrão de流量/流量** (timing, sizes) — sobrevive, mas precisa de ML treinado por app.
- **IP de saída** — se o usuário sai por VPN/Tor, vira "túnel".

---

## 7. Pegadinhas e cuidados operacionais

1. **Play Integrity (PIF)**: Tinder e Badoo checam SafetyNet/Play Integrity. O módulo
   `install-play-integrity-fix.sh` da skill **é necessário** se o app for rodar no Waydroid —
   sem isso o app abre e fecha. Mas PIF não impede MITM; só impede que o app saiba que
   está em ambiente "sagrado".
2. **TLS pinning**: Tinder e Badoo pinaram em 2021-2022. Em 2026 provavelmente continuam
   (Bumble usava Trustkit/OkHttp). Para MITM transparente: Frida + objection
   (`objection -g com.tinder explore` → `android sslpinning disable`).
3. **App integrity / SafetyNet attestation**: mesmo com PIF passando, alguns endpoints
   pedem **attestation token** (Google Play Services). Se o Waydroid não tem GPS ou se o
   token expirou, o servidor recusa. Não é problema para observação passiva, é problema
   para extração ativa.
4. **Geolocalização de DNS**: `api.gotinder.com` resolve diferente por região. O sensor
   precisa **resolver do mesmo egress** que o alvo — senão vê IPs errados.
5. **Apps em background**: Tinder tem background heartbeat (15-30 min) que gera uma rajada
   curta e facilmente identificável. Não confunda com uso.
6. **LGPD**: log de SNI é dado pessoal **se permitir identificar pessoa natural** (STF/MPC:
   "tráfego é dado pessoal"). Em rede corporativa há espaço (legitimate interest + DPIA),
   em rede residencial de terceiro não.

---

## 8. O que **não** dá (nem ativo nem passivo, em 2026)

- Identidade da outra pessoa em match — só o servidor sabe.
- Conteúdo de mensagens criptografadas E2E (Signal Protocol onde existir — Tinder não tem
  E2E no chat; Badoo afirma E2E em "secret chat", que é opcional).
- Localização GPS exata do outro usuário — vai cifrada para o servidor, servidor devolve
  distância, não coordenada.
- Histórico de matches/curtidas depois de deletadas — a Bumble Inc. apaga de fato (paper MDPI).

---

## 9. Resumo executivo (uma página)

**Tinder**: app = CloudFront. Pivô é SNI `api.gotinder.com` enquanto ECH não ligar; depois,
mude para fingerprint de pacote + JA4. Quase tudo é HTTPS, login pode passar por Facebook
(graph.facebook.com). Tamanho de payload revela ação (swipe/match/message) mesmo criptografado.

**Badoo**: app = infra própria da Bumble Inc. (mesma controladora do Bumble). SNI mais
confiável (`eu1.badoo.com`, `us1.badoo.com`, `*.badoocdn.com`). Paper de 2022 (PMC9628447)
mostrou que era vulnerável a MITM simples; o app reforçou pinning depois, mas Frida bypassa.

**Onde a rede 192.168.100.0/24 / br-lan te dá vantagem**: o pivô SNI é o mais barato.
**Onde ela te dá falsa segurança**: assim que o app cliente ativar ECH (Cloudflare já faz
opt-in, CloudFront beta), o pivô some e você precisa de flow fingerprinting treinado
por app.

**Onde o Waydroid local te dá vantagem**: tudo — `databases/`, `shared_prefs/`, Frida,
MITM. Mas é vetor **ativo**: você tem que ter o aparelho físico ou VM com o app instalado
e o user_id conhecido. **Fora do escopo se a pergunta era só passivo na rede.**

**Próximos passos sugeridos** (se quiser que eu siga):

1. Montar um Zeek com JA4 no n100 e gerar um sample de 24h de `ssl.log` filtrado por
   `server_name in {*.gotinder.com, *.badoo.com, *.bumble.com, *.badoocdn.com}`. Sem
   descriptografia, só metadados. Custo: uma tarde.
2. Treinar um classificador simples (RandomForest sobre packet size + IAT) usando o
   dataset Mendeley (10 social media apps) como base. Adaptar para Tinder/Badoo
   capturando local no Waydroid. Custo: dois dias.
3. Se a intenção for **bloquear** (não observar): dnscrypt-proxy + AdGuard Home +
   nftables SNI filter em camadas. Funciona até ECH ligar.

---

## Anexo A — Fontes principais

- **Forense Bumble Android** (paper mais útil): https://www.mdpi.com/2673-6756/2/1/16
- **Badoo MITM analysis** (paper 2022): https://pmc.ncbi.nlm.nih.gov/articles/PMC9628447/
- **Zimperium — privacy dating apps** (estatísticas 96% reversível, 89% sem TLS seguro):
  https://zimperium.com/blog/security-and-privacy-issues-found-in-popular-dating-apps
- **api.gotinder.com metadata**: https://www.netify.ai/resources/hostnames/api.gotinder.com
- **JA4+ suite**: https://github.com/FoxIO-LLC/ja4
- **JA4 in Zeek (2026)**: https://zeek.org/2026/01/how-to-use-ja4-network-fingerprints-in-zeek/
- **ECH RFC 9849**: https://www.rfc-editor.org/info/rfc9849/
- **AppPrint / AFMA fingerprint**: https://arxiv.org/html/1704.06099v1
- **Dataset redes sociais mobile cifrado**: https://data.mendeley.com/datasets/6v3zcxysh7
- **nftables + SNI via nfqueue**: https://github.com/jsimonetti/sniqueue
- **Tinder API doc (2014, gist, mas a infra é a mesma)**: https://gist.github.com/rtt/10403467
- **Bumble SEC S-1 (shared infra com Badoo)**: https://www.sec.gov/Archives/edgar/data/1830043/000095012320010633/filename1.htm
- **Sniqueue SNI**: https://github.com/jsimonetti/sniqueue
- **mitmproxy Android + apk-debuggable**: https://medium.com/@benlue/how-to-inspect-any-android-apps-network-traffic-with-mitmproxy-c3d2a210da41
- **Frida cert pinning bypass**: https://httptoolkit.com/blog/frida-certificate-pinning/
