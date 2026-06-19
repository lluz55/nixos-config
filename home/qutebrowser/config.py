# ==============================================================================
# Qutebrowser Configuration File (config.py)
# ==============================================================================
# Documentação oficial: https://qutebrowser.org/doc/help/configuring.html
# ==============================================================================

# Carrega as configurações feitas através da UI (como :set ou :bind) salvas no autoconfig.yml
config.load_autoconfig(True)

# ==============================================================================
# 1. MECANISMOS DE BUSCA (Search Engines)
# ==============================================================================
# Configura o buscador padrão e atalhos para buscas rápidas.
# O placeholder {} é onde o termo pesquisado será inserido.
c.url.searchengines = {
    # Buscador padrão: Google (Conforme solicitado)
    'DEFAULT': 'https://www.google.com/search?q={}',

    # Atalho para o YouTube (Ex: ':open y python tutorial' na barra de endereços)
    'y': 'https://www.youtube.com/results?search_query={}',
    'yt': 'https://www.youtube.com/results?search_query={}',

    # Sugestões adicionais de buscadores úteis:
    'ddg': 'https://duckduckgo.com/?q={}',
    'gh': 'https://github.com/search?q={}',
    'wikipedia': 'https://pt.wikipedia.org/wiki/Special:Search?search={}',
}

# Atalho de teclado para abrir a barra de pesquisa pré-preenchida com o YouTube (y)
# Ao digitar ',y', a barra de comando abrirá pronta para você digitar sua busca no YouTube.
config.bind(',y', 'set-cmd-text -s :open -t y ')

# ==============================================================================
# 2. ATALHOS DE NAVEGAÇÃO RAPIDA (Leader Key: ',')
# ==============================================================================
# Atalhos usando ', <primeira letra do site>' para abrir em uma nova aba (-t)
# Reddit
config.bind(',r', 'open -t https://www.reddit.com')
# Hugging Face Models
config.bind(',h', 'open -t https://huggingface.co/models')
# Frigate (Aponte para o IP/porta do seu servidor local caso seja diferente de localhost)
config.bind(',f', 'open -t http://localhost:5000')

# ==============================================================================
# 3. TOGGLE DE TEMA (Escuro / Claro)
# ==============================================================================
# Atalho para alternar o modo escuro nas páginas da web
# Você pode usar ',t' (consistente com seus atalhos) ou o padrão 'td'
config.bind(',t', 'config-cycle colors.webpage.darkmode.enabled')
config.bind('td', 'config-cycle colors.webpage.darkmode.enabled')

# Algoritmo de modo escuro aprimorado (sugestão estética para tons mais naturais)
c.colors.webpage.darkmode.algorithm = 'lightness-cielab'

# ==============================================================================
# 4. SUGESTÕES EXTRAS PARA MELHORAR SUA NAVEGAÇÃO (Power-User)
# ==============================================================================

# --- Bloqueador de Anúncios (Adblocker) ---
# Ativa o Adblock nativo do Brave (rápido e extremamente eficiente)
c.content.blocking.method = 'adblock'
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt"
]

# --- Rolagem Suave (Smooth Scrolling) ---
# Torna a experiência de leitura muito mais fluida
c.scrolling.smooth = True

# --- Corretor Ortográfico ---
# Habilita o corretor em Português e Inglês
c.spellcheck.languages = ['pt-BR', 'en-US']

# --- Sessão Automática ---
# Salva a sessão ao fechar e restaura as abas abertas ao iniciar o navegador
c.auto_save.session = True

# --- Interface Minimalista ---
# Oculta a barra de abas se houver apenas 1 aba aberta, maximizando o espaço útil
c.tabs.show = 'multiple'

# --- Atalhos para Assistir Vídeos Externamente (MPV) ---
# Se você tiver o tocador 'mpv' instalado, estes atalhos abrem o vídeo atual
# (ou o link selecionado) diretamente no player externo, livre de anúncios e leve.
# ,m -> Abre a página atual no MPV
config.bind(',m', 'spawn mpv {url}')
# ,M -> Abre o link destacado (hints) no MPV
config.bind(',M', 'hint links spawn mpv {hint-url}')
