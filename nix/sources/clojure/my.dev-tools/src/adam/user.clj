(ns adam.user)

(require
  ;; requiring snitch interns these four methods in clojure.core
 '[snitch.core :refer [defn* defmethod* *fn *let]]
 '[clojure.java.javadoc :refer (javadoc)]
 '[clojure.pprint :refer (pp pprint)]
 '[clojure+.error]
 '[clojure+.test]
 '[portal.api :as portal]
 '[clj-java-decompiler.core :refer [decompile]]
 '[criterium.core :as cr]
  ;; '[dev.nu.morse :as morse]
 )

(clojure+.error/install!)
(clojure+.test/install!)

(intern 'clojure.core (with-meta 'ppr (meta #'pprint)) #'pprint)
(intern 'clojure.core (with-meta 'pp (meta #'pp)) #'pp)
(intern 'clojure.core (with-meta 'javadoc (meta #'javadoc)) #'javadoc)
;; (intern 'clojure.core (with-meta 'portal (meta #'open)) #'open)
;; (intern 'clojure.core (with-meta 'insp (meta #'morse/inspect)) #'morse/inspect)
;; (morse/launch-in-proc)

(declare p)

(defn portal!
  []
  (prn "starting portal...")
  (def p (portal/open))
  (add-tap #'portal/submit))

(defn t>
  ([& args]
   (if (= 1 (count args))
     (tap> (first args))
     (tap> (into
            (vector
             (second args)
             (first args))
            (drop 2 args))))
   (first args)))

(defn t>>
  [& args]
  (if (= 1 (count args))
    (tap> (first args))
    (tap> (vec args)))
  (last args))

(intern 'clojure.core (with-meta 'portal! (meta #'portal!)) #'portal!)
(intern 'clojure.core (with-meta 't> (meta #'t>)) #'t>)
(intern 'clojure.core (with-meta 't>> (meta #'t>>)) #'t>>)

(intern 'clojure.core (with-meta 'decomp (meta #'decompile)) #'decompile)

;; Benchmarking ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(let [time*
      (fn [^long duration-in-ms f]
        (let [^com.sun.management.ThreadMXBean bean (java.lang.management.ManagementFactory/getThreadMXBean)
              bytes-before (.getCurrentThreadAllocatedBytes bean)
              duration (* duration-in-ms 1000000)
              start (System/nanoTime)
              first-res (f)
              delta (- (System/nanoTime) start)
              deadline (+ start duration)
              tight-iters (max (quot (quot duration delta) 10) 1)]
          (loop [i 1]
            (let [now (System/nanoTime)]
              (if (< now deadline)
                (do (dotimes [_ tight-iters] (f))
                    (recur (+ i tight-iters)))
                (let [i' (double i)
                      bytes-after (.getCurrentThreadAllocatedBytes bean)
                      t (/ (- now start) i')]
                  (println
                   (format "Time per call: %s   Alloc per call: %,.0fb   Iterations: %d"
                           (cond (< t 1e3) (format "%.0f ns" t)
                                 (< t 1e6) (format "%.2f us" (/ t 1e3))
                                 (< t 1e9) (format "%.2f ms" (/ t 1e6))
                                 :else (format "%.2f s" (/ t 1e9)))
                           (/ (- bytes-after bytes-before) i')
                           i))
                  first-res))))))]
  (defmacro time+
    "Like `time`, but runs the supplied body for 2000 ms and prints the average
  time for a single iteration. Custom total time in milliseconds can be provided
  as the first argument. Returns the returned value of the FIRST iteration."
    [?duration-in-ms & body]
    (let [[duration body] (if (integer? ?duration-in-ms)
                            [?duration-in-ms body]
                            [2000 (cons ?duration-in-ms body)])]
      `(~time* ~duration (fn [] ~@body)))))

(intern 'clojure.core (with-meta 'time+ (meta #'time+)) #'time+)

(defmacro compare-bench-mean
  [& args]
  (->> (partition 2 args)
       (map (fn [[k expr]]
              [k `(let [mean#           (first (:sample-mean (cr/quick-benchmark ~expr {})))
                        [factor# unit#] (cr/scale-time mean#)]
                    [mean# (cr/format-value mean# factor# unit#)])]))
       (into {})))

;; Observability ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro dspy
  [sym & body]
  `(let [out# ~@(do body)]
     (def ~sym out#)
     out#))

(intern 'clojure.core (with-meta 'dspy (meta #'dspy)) #'dspy)

(defmacro doas
  [binding x & body]
  `(let [~binding ~x]
     (do ~@body)
     ~binding))

(intern 'clojure.core (with-meta 'doas (meta #'doas)) #'doas)
