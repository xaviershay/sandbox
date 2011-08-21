; A basic lisp interpreter, based on SICP chapter 4.
; See tests at bottom of file for usage.
(ns lisptwo
    (:use clojure.test))

; Forward declarations
(declare env-get env-set env-extend seq-to-map)
(declare context context-exp context-env)
(declare self-evaluating? if-eval seq-eval map-eval)
(declare do-apply primitive-fn? primitive-fns)
(declare make-fn fn-args fn-body)

(defn do-eval [exp env] "Main eval loop"
  (let [tagged? #(= % (first exp))]
    (cond (self-evaluating? exp) (context exp env)
          (symbol? exp)          (context (env-get env exp) env)
          (tagged? 'set)         (context (last exp) (env-set env (seq-to-map (rest exp))))
          (tagged? 'if)          (if-eval exp env)
          (tagged? 'fn)          (context (make-fn exp env) env)
          (tagged? 'begin)       (seq-eval (rest exp) env)
          (list? exp)            (do-apply (first exp) (rest exp) env)
          :else (context 'fail env))))

(defn do-apply [f arg-values env] "Main apply function"
  (let [arg-values-eval (map-eval arg-values env)
        fn-result
          (if (primitive-fn? f)
            (apply (primitive-fns f) (context-exp arg-values-eval))
            (let [env (env-extend env (fn-args f) (context-exp arg-values-eval))]
              (first (do-eval (fn-body f) env))))]
    (context fn-result (context-env arg-values-eval))))

(defn context [exp env] [exp env])
(def context-exp first)
(def context-env last)

(defn make-fn [exp env]
  (list 'procedure (nth exp 1) (nth exp 2) env))
(defn fn-args [f] (nth f 1))
(defn fn-body [f] (nth f 2))

(defn detect [f coll]
  (first (filter f coll)))
(defn env-set [env pair]
  (concat [(merge (first env) pair)] (rest env)))
(defn env-get [env label]
  (let [matching-env (detect #(contains? % label) env)]
    (if (nil? matching-env)
        'fail-var-lookup
        (matching-env label))))
(defn env-extend [env labels values]
  (concat [(apply array-map (interleave labels values))] env))
(defn seq-to-map [seq]
  (apply array-map seq))

(def primitive-fns {
  '+ +
  '- -
  '* *
  '/ /
  'println println
  })
(defn primitive-fn? [f]
  (contains? primitive-fns f))

(defn self-evaluating? [exp]
  (cond (number? exp) true
        (string? exp) true
        (instance? Boolean exp) true
        :else         false))
(defn if-eval [exp env]
  (let [predicate   (nth exp 1)
        consequent  (nth exp 2)
        alternative (if (= 4 (count exp)) (nth exp 3) false)]
    (let [predicate-eval   (do-eval predicate env)
          predicate-result (first predicate-eval)
          env              (last predicate-eval)]
      (if predicate-result
        (do-eval consequent env)
        (do-eval alternative env)))))

(defn map-reducer [a x]
  (let [result (do-eval x (last a))]
    (context (conj (first a) (first result)) (last result))))
(defn last-exp-reducer [a x]
  (do-eval x (last a)))
(defn make-seq-eval [reducer]
  (fn [exps env]
    (reduce reducer (context [] env) exps)))
(def seq-eval (make-seq-eval last-exp-reducer))
(def map-eval (make-seq-eval map-reducer))

; Tests
(defn run [exp env]
  (do-eval exp env))

(defn run-val
  ([exp] (run-val exp {}))
  ([exp env] (first (run exp [env])))
  )

(defn run-env
  ([exp] (run-env exp {}))
  ([exp env] (first (last (run exp [env]))))
  )

(deftest evaluator-tests
         (is (= 1      (run-val 1)))
         (is (= "1"    (run-val "1")))
         (is (= false  (run-val false)))
         (is (= 2      (run-val '(begin 1 2))))
         (is (= 1      (run-val 'x {'x 1})))
         (is (= 1      (run-val '(begin x) {'x 1})))
         (is (= 1      (run-val '(begin (set x 1) x))))
         (is (= 1      (run-val '((fn [] 1)))))
         (is (= 1      (run-val '((fn [] x)) {'x 1})))
         (is (= 1      (run-val '((fn [x] x) 1) {'x 2})))
         (is (= 2      (run-val '(begin ((fn [x] x) 1) x) {'x 2})))
         (is (= false  (run-val '(if false 1))))
         (is (= 1      (run-val '(if true 1 2))))
         (is (= 2      (run-val '(if false 1 2))))
         (is (= 1      (run-val '(if (set x 1) x))))
         (is (= 3      (run-val '(+ 1 (+ 1 1)))))
         (is (= 3      (run-val '(+ 1 2))))
         (is (= 3      (run-val '(- 5 2))))
         (is (= 6      (run-val '(* 3 2))))
         (is (= 3      (run-val '(/ 6 2))))
         (is (= {'x 1} (run-env '(set x 1))))
         (is (= {'x 1} (run-env '(+ (set x 1)))))
         )

(run-tests)
