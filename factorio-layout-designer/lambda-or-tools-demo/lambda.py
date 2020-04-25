import sys
import json
import base64

from ortools.linear_solver import pywraplp

def coalesce(x, default):
    return default if x is None else x

def lambda_handler(event, context):
    params = json.loads(base64.b64decode(event['body']))

    solver = pywraplp.Solver('simple_lp_program',
                          pywraplp.Solver.GLOP_LINEAR_PROGRAMMING)

    vars = {}

    for k, v in params['variables'].items():
        vars[k] = solver.NumVar(
            coalesce(v[0], sys.float_info.min),
            coalesce(v[1], sys.float_info.max),
            k
        )

    for c in params['constraints']:
        ct = solver.Constraint(
            coalesce(c['range'][0], sys.float_info.min),
            coalesce(c['range'][1], sys.float_info.max)
        )
        for k, v in c['coefficients'].items():
            ct.SetCoefficient(vars[k], v)

    objective = solver.Objective()
    for k, v in params['objective']['coefficients'].items():
        objective.SetCoefficient(vars[k], v)

    objective_type = params['objective']['type']

    if objective_type == 'max':
        objective.SetMaximization()
    elif objective_type == 'min':
        objective.SetMinimization()
    else:
        raise Exception("Unknown objective type: {}".format(objective_type))

    status = solver.Solve()

    if status == pywraplp.Solver.OPTIMAL:
        result = {}
        for k, v in vars.items():
            result[k] = round(v.solution_value(), 5)

        return {
            'statusCode': 200,
            'body': json.dumps({
                "solved": True,
                "variables": result
            }) + "\n"
        }
    else:
        return {
            'statusCode': 200,
            'body': json.dumps({
                'solved': False
            }) + "\n"
        }
