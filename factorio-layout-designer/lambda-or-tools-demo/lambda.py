import json
import base64

from ortools.linear_solver import pywraplp

def lambda_handler(event, context):
    params = json.loads(base64.b64decode(event['body']))

    solver = pywraplp.Solver('simple_lp_program',
                          pywraplp.Solver.GLOP_LINEAR_PROGRAMMING)

    vars = {}

    for k, v in params['variables'].items():
        vars[k] = solver.NumVar(v[0], v[1], k)

    for c in params['constraints']:
        ct = solver.Constraint(c['range'][0], c['range'][1])
        for k, v in c['coefficients'].items():
            ct.SetCoefficient(vars[k], v)

    objective = solver.Objective()
    for k, v in params['objective']['coefficients'].items():
        objective.SetCoefficient(vars[k], v)

    objective.SetMaximization()

    solver.Solve()

    result = {}
    for k, v in vars.items():
        result[k] = v.solution_value()

    return {
        'statusCode': 200,
        'body': json.dumps({
            "solved": True,
            "variables": result
        }) + "\n"
    }
