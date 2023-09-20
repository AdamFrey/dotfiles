(ns user)

(require
  '[snitch.core :refer [defn* defmethod* *fn *let]]
  '[clojure.java.javadoc :refer (javadoc)]
  '[clojure.pprint :refer (pp pprint)]
  '[dev.nu.morse :as morse])

(intern 'clojure.core (with-meta 'ppr (meta #'pprint)) #'pprint)
(intern 'clojure.core (with-meta 'pp (meta #'pp)) #'pp)
(intern 'clojure.core (with-meta 'javadoc (meta #'javadoc)) #'javadoc)
(intern 'clojure.core (with-meta 'insp (meta #'morse/inspect)) #'morse/inspect)
;; (morse/launch-in-proc)
