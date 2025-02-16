from json import loads, JSONDecodeError

from requests import Response, post

api_server_url = f"https://deploy-1033307567210.europe-north1.run.app"

def gen_triples_33(n_examples:int, 
    max_ast_depth:int = 3, 
    n_stmt:int = 5, 
    n_pre_terms:int = 1, 
    n_post_terms:int = 1,
    endpoint = '/gen33',
    seed:int = 1234):
    cfg = {
        "n_examples": n_examples,
        "max_ast_depth": max_ast_depth,
        "n_stmt": n_stmt,
        "n_pre_terms": n_pre_terms,
        "n_post_terms": n_post_terms,
        "sm_gen_seed": seed,
        "sm_gen_gamma": 1
        }
    url = f"{api_server_url}/{endpoint}"
    res = post(url, json= cfg, stream= True)
    if res.ok:
        for chunk in res.iter_lines(chunk_size= None, delimiter=b"\r\n"):
            try:
                v = loads(chunk)
                if not isinstance(v, dict):
                    v = None
            except JSONDecodeError as e:
                v = None
            if v is not None: 
                print(v)
    

def verify_triples(
    is_total:bool = True,
    preconditions:str = "True",
    program:str = "v4 = (0 - v3)\nv3 = v3\nv5 = v4",
    postconditions:str = "v5 == (0 - v3)",
    endpoint:str = '/prove33'):
    cfg = {
        "is_total": is_total,
        "post": postconditions,
        "pre": preconditions,
        "program": program
    }
    url = f"{api_server_url}/{endpoint}"
    res = post(url, json= cfg, stream= True)
    if res.ok:
        try:
            v = res.json()
        except JSONDecodeError:
            v = None
        print(v)



if __name__ == "__main__":
    gen_triples_33(n_examples= 2)
    verify_triples( is_total= True)