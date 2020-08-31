import requests

class RestApiClient:
    def __init__(self, root_url="http://localhost:5000/api"):
        self.__session_id=None
        self.__cookies=None
        self.__root=f"{root_url}/v1.0"

    def login(self, username, password):
        headers={
            "username":username,
            "password":password
        }

        r=requests.post(f'{self.__root}/core/login', headers=headers)

        if r.status_code==200:
            session=r.cookies['session']
        else:
            session=None

        if r.status_code!=200:
            raise NameError(f"{r.text}")

        self.__cookies={"session": session}
        self.__session_id=session
        return r.text

    def logoff(self):
        r=requests.post(f'{self.__root}/core/logoff', cookies=self.__cookies)
        self.__session_id=None
        if r.status_code!=200:
            raise NameError(f"{r.text}")
        return r.text

    def delete(self, table, id):
        url=f"{self.__root}/data/{table}/{id}"
        r=requests.delete(url, cookies=self.__cookies)
        print(r.status_code)
        if r.status_code!=200:
            raise NameError(f"{r.status_code} {r.text}")
        return r.text

    def add(self, table,data):
        url=f"{self.__root}/data/{table}"
        headers={"Content-Type":"application/json"}
        r=requests.post(url, headers=headers, json=data, cookies=self.__cookies)
        if r.status_code!=200:
            raise NameError(f"{r.status_code} {r.text}")
        return r.text

    def read(self, table, id):
        url=f"{self.__root}/data/{table}/{id}"
        r=requests.get(url, cookies=self.__cookies)
        if r.status_code!=200:
            raise NameError(f"{r.status_code} {r.text}")
        return r.text

    def update(self,table,id, data):
        url=f"{self.__root}/data/{table}/{id}"
        headers={"Content-Type":"application/json"}
        r=requests.put(url, headers=headers, json=data, cookies=self.__cookies)
        if r.status_code!=200:
            raise NameError(f"{r.status_code} {r.text}")
        return r.text

    def read_multible(self, table, fetchxml=None):
        url=f"{self.__root}/data/{table}"
        r=requests.get(url, cookies=self.__cookies)
        if r.status_code!=200:
            raise NameError(f"{r.status_code} {r.text}")
        return r.text


if __name__=='__main__':
    client=RestApiClient()
    client.login("guest", "password")
    client.logoff()
    print(client.add("dummy", {'id':99,'name':'IC735', 'port':3306}))

    print(client.delete("dummy",99))
    print(client.delete("dummy",100))
    print(client.add("dummy", {'id':99,'name':'IC735', 'port':3306}))
    print(client.add("dummy", {'id':100,'name':'TEST', 'port':3306}))
    print(client.read("dummy", 99))
    print(client.update("dummy", 99, {'id':99,'name':'GD77', 'port':3307}))
    print(client.read("dummy", 99))
    print(client.read_multible("dummy"))
    print(client.logoff())



