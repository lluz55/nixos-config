{ lib, ... }:
{
  xdg.configFile = {
    "qutebrowser/config.py" = {
      force = true;
      text = lib.mkForce ''
        config.load_autoconfig(True)

        c.url.searchengines = {
            'DEFAULT': 'https://www.google.com/search?q={}',
            'y': 'https://www.youtube.com/results?search_query={}',
            'yt': 'https://www.youtube.com/results?search_query={}',
            'ddg': 'https://duckduckgo.com/?q={}',
            'gh': 'https://github.com/search?q={}',
            'wikipedia': 'https://pt.wikipedia.org/wiki/Special:Search?search={}',
        }

        config.bind(',y', 'set-cmd-text -s :open -t y ')
        config.bind(',r', 'open -t https://www.reddit.com')
        config.bind(',h', 'open -t https://huggingface.co/models')
        config.bind(',f', 'open -t http://localhost:5000')
        config.bind(',t', 'config-cycle colors.webpage.darkmode.enabled')
        config.bind('td', 'config-cycle colors.webpage.darkmode.enabled')
        config.bind(',m', 'spawn mpv {url}')
        config.bind(',M', 'hint links spawn mpv {hint-url}')

        c.auto_save.session = True
        c.colors.webpage.darkmode.algorithm = 'lightness-cielab'
        c.content.blocking.method = 'both'
        c.content.blocking.adblock.lists = [
            'https://easylist.to/easylist/easylist.txt',
            'https://easylist.to/easylist/easyprivacy.txt',
            'https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt',
        ]
        c.scrolling.smooth = True
        c.spellcheck.languages = ['pt-BR', 'en-US']
        c.tabs.show = 'multiple'

        config.set('content.javascript.clipboard', 'access-paste', 'https://antigravity.google')
        config.set('content.javascript.clipboard', 'access-paste', 'https://github.com')
      '';
    };

    "qutebrowser/autoconfig.yml" = {
      force = true;
      text = lib.mkForce ''
        config_version: 2
        settings: {}
      '';
    };

    "qutebrowser/quickmarks" = {
      force = true;
      text = lib.mkForce ''
        o usa https://www.youtube.com/
      '';
    };

    "qutebrowser/bookmarks/urls" = {
      force = true;
      text = lib.mkForce "";
    };
  };
}
