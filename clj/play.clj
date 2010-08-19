(defn self-evaluating? [exp]
  (cond (number? exp) true
        (string? exp) true
        true          false))

(defn variable? [exp] (symbol? exp))
(defn lookup-variable-value [exp env]
  (get env exp))

(defn application? [exp] (list? exp))

(defn myeval [exp env]
  (cond (self-evaluating? exp) exp
        (variable?        exp) (lookup-variable-value exp env)
        (application?     exp) 
          (apply 
            (eval (first exp)) 
            (map 
              (fn [x] (myeval x env)) 
              (rest exp)))
        true 
          (str "Unknown expression type -- EVAL")))

'TESTS

(defn check [expected fn env]
  (let [actual (myeval fn env)]
    (if (= expected actual) 
      (println "pass") 
      (println (str "fail " actual)))))

(check 1   1   (hash-map))
(check "A" "A" (hash-map))
(check 2   'a  (hash-map 'a 2))
(check 2   '(+ 1 1)    (hash-map 'a 2))
(check 3   '(+ a 1)    (hash-map 'a 2))
(check 6   '(+ a (+ b 1))    (hash-map 'a 2 'b 3))
