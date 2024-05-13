import urllib3
import time
import requests
from app.config import Config
from pymongo import MongoClient
from requests.exceptions import ReadTimeout

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


CONTENT_CHUNK_SIZE = 10 * 1024


UA = "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"


proxies = {
    'https': "http://127.0.0.1:8080",
    'http': "http://127.0.0.1:8080"
}

SET_PROXY = False


# requests/models.py:824
def patch_content(response, timeout=None):
    """Content of the response, in bytes."""
    start_at = time.time()
    if response._content is False:
        # Read the contents.
        if response._content_consumed:
            raise RuntimeError("The content for this response was already consumed")

        if response.status_code == 0 or response.raw is None:
            response._content = None
        else:
            body = b''
            for part in response.iter_content(CONTENT_CHUNK_SIZE):
                body += part
                if timeout is not None and time.time() - start_at >= timeout:
                    raise ReadTimeout(f"patch_content read http response timeout: {timeout}")
            response._content = body
    response._content_consumed = True
    # don't need to release the connection; that's been handled by urllib3
    # since we exhausted the data.
    return response._content


def http_req(url, method='get', **kwargs):
    kwargs.setdefault('verify', False)
    kwargs.setdefault('timeout', (10.1, 30.1))
    kwargs.setdefault('allow_redirects', False)

    headers = kwargs.get("headers", {})
    headers.setdefault("User-Agent", UA)
    # 不允许缓存
    headers.setdefault("Cache-Control", "max-age=0")

    kwargs["headers"] = headers
    kwargs["stream"] = True

    if Config.PROXY_URL:
        proxies['https'] = Config.PROXY_URL
        proxies['http'] = Config.PROXY_URL
        kwargs["proxies"] = proxies

    conn = getattr(requests, method)(url, **kwargs)

    timeout = kwargs.get("timeout")
    if len(timeout) > 1 and timeout[1]:
        timeout = timeout[1]

    patch_content(conn, timeout)

    return conn


class ConnMongo(object):
    def __new__(self):
        if not hasattr(self, 'instance'):
            self.instance = super(ConnMongo, self).__new__(self)
            self.instance.conn = MongoClient(Config.MONGO_URL)
        return self.instance


def conn_db(collection, db_name = None):
    conn = ConnMongo().conn
    if db_name:
        return conn[db_name][collection]

    else:
        return conn[Config.MONGO_DB][collection]