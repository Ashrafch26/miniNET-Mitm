import http
import requests as rq
import json


try :
    r=rq.get("http://10.86.167.41:80/")  
    if r.status_code != 200 : 

        raise Exception("server is out") 
except Exception as e:
    print(e)
else :
    print(r.text)
