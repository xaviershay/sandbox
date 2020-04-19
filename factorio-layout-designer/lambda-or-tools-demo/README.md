* Created an or-tools lambda layer myself (the pre-built one didn't work), updated to 3.8 as well: https://github.com/matheusmessora/or-tools-layer/pull/1

* Paste `lambda.py` into a lambda function
* Used API Gateway to make REST API to lambda function. So easy!

    > time curl https://sa6mifk9pb.execute-api.us-east-1.amazonaws.com/solveLP --data @data.json
    {"solved": true, "variables": {"x": 1.5909090909090908, "y": 1.3636363636363638, "z": 4.0}}
    curl https://sa6mifk9pb.execute-api.us-east-1.amazonaws.com/solveLP --data   0.01s user 0.01s system 1% cpu 1.286 total
