import http
import requests as rq
import json

data = {
    "username": "admin",
    "password": "admin"
}

def get_server():
    try :
        r=rq.get("http://127.0.0.1:80/")  
        if r.status_code != 200 : 

            raise Exception("server is out") 
    except Exception as e:
        print(e)
    else :
        print(r.text)


def post_server():
    try:
        r = rq.post(
            "http://127.0.0.1:80/login",
            data=data
            )
        print(r.status_code)

    except Exception as e:
        print(e)
    else :
        print(r.text)

# get_server()
post_server()
