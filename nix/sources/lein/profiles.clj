{:user {:dependencies
        [[djblue/portal "0.51.1"]
         [io.github.paintparty/fireworks "0.10.4"]
         [io.github.tonsky/clojure-plus "1.5.0"]
         [org.clojars.abhinav/snitch "0.1.16"
          :exclusions [org.clojure/clojurescript]]
         [com.clojure-goes-fast/clj-java-decompiler "0.3.3"]
         [cider/cider-nrepl "0.45.0"]
         [refactor-nrepl/refactor-nrepl "3.9.1"]
         [org.clojure/tools.namespace "1.4.4"]
         [vvvvalvalval/scope-capture "0.3.3"]]
        :resource-paths ["/home/adam/src/dotfiles/nix/sources/clojure/my.dev-tools/src"]
        :plugins        [[cddr/lein-pprint "1.3.2"]]
        :injections     [(require 'sc.api)]}}
