; A basic lisp interpreter, based on SICP chapter 4.
; See tests at bottom of file for usage.
(ns lisptwo
    (:use clojure.test))

; Forward declarations
(declare env-get env-set env-extend seq-to-map)
(declare context context-exp context-env)
(declare self-eval? if-eval seq-eval map-eval)
(declare do-apply primitive-fn? primitive-fns fn-apply pr-apply)
(declare make-fn fn-args fn-body)

(defmacro def-context-fn 
  "Defines a fn that takes as its sole argument a context, and creates bindings 
  `c`, `exp` and `env` from that context for use in the fn."
  [name arg-names & body]
  (let [c#   (nth arg-names 0)
        exp# (nth arg-names 1)
        env# (nth arg-names 2)]
  `(defn ~name [~c#]
     (let [~exp# (context-exp ~c#)
           ~env# (context-env ~c#)]
       ~@body))))

(def-context-fn do-eval [c exp env]; "Main eval loop"
  (let [tagged? #(= % (first exp))]
    (cond (self-eval? exp) c
          (symbol? exp)    (context (env-get env exp) env)
          (tagged? 'set)   (context (last exp) (env-set env (seq-to-map (rest exp))))
          (tagged? 'if)    (if-eval c)
          (tagged? 'fn)    (context (make-fn c) env)
          (tagged? 'begin) (seq-eval (context (rest exp) env))
          (list? exp)      (do-apply c)
          :else (context 'fail env))))

(def-context-fn do-apply [c exp env] ; "Main apply function"
  (let [f         (first exp)
        args-context (map-eval (context (rest exp) env))
        args         (context-exp args-context)
        env          (context-env args-context)
        applier      (if (primitive-fn? f) pr-apply fn-apply)]
    (context (applier env f args) env)))

(defn pr-apply [env f args]
  (apply (primitive-fns f) args))
(defn fn-apply [env f args]
    (let [env (env-extend env (fn-args f) args)]
      (-> (do-eval (context (fn-body f) env)) context-exp)))

(defn context [exp env] {'exp exp, 'env env})
(defn context-exp [c] (c 'exp))
(defn context-env [c] (c 'env))

(def-context-fn make-fn [c exp env]
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

(defn self-eval? [exp]
  (cond (number? exp) true
        (string? exp) true
        (instance? Boolean exp) true
        :else         false))

(def-context-fn if-eval [c exp env]
  (let [predicate   (nth exp 1)
        consequent  (nth exp 2)
        alternative (if (= 4 (count exp)) (nth exp 3) false)

        predicate-context (do-eval (context predicate env))
        predicate-result  (context-exp predicate-context)
        env               (context-env predicate-context)]
    (do-eval (if predicate-result
      (context consequent  env)
      (context alternative env)))))

(defn map-reducer [a x]
  (let [result (do-eval (context x (context-env a)))]
    (context (conj (context-exp a) (context-exp result)) (context-env result))))
(defn last-exp-reducer [a x]
  (do-eval (context x (context-env a))))
(def-context-fn seq-eval [c exp env]
  (reduce last-exp-reducer (context nil env) exp))
(def-context-fn map-eval [c exp env]
  (reduce map-reducer      (context [] env) exp))

; Tests
(defn run [exp env]
  (do-eval (context exp env)))

(defn run-val
  ([exp] (run-val exp {}))
  ([exp env] (-> (run exp [env]) context-exp))
  )

(defn run-env
  ([exp] (run-env exp {}))
  ([exp env] (-> (run exp [env]) context-env first))
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
         (is (= 2      (run-val '((fn [y] x) (set x 2)) {'x 1})))
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
