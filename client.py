import http
import requests as rq
import json


try :
    r=rq.get("http://127.0.0.1:80/")  
    if r.status_code != 200 : 

        raise Exception("server is out") 
except Exception as e:
    print(e)
else :
    print(r.text)
