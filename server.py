from flask import Flask


app = Flask(__name__)

@app.route('/')
def home():
    return "<h1>welcome to the hood</h1>"


if __name__=='__main__':
    app.run('127.0.0.1',80,True) # wee can use here another address and it's depend on the network addressing