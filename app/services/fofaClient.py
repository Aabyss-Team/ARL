#  -*- coding:UTF-8 -*-
import base64
from app.config import Config
from app import utils
import time
logger = utils.get_logger()


class FofaClient:
    def __init__(self, key, page_size=2000, max_page=5, fields="host,ip,port"):
        self.key = key
        self.page_size = page_size
        self.max_page = max_page
        self.base_url = Config.FOFA_URL.rstrip("/")
        self.search_all_path = "/api/v1/search/all"
        self.base_params = {
            "key": self.key,
        }
        self.fields = fields

    def search(self, query):
        page = 1
        while True:
            if page > self.max_page:
                break
            if page > 1:
                time.sleep(0.2)

            data = self.fofa_search_all(query, page)
            logger.debug(f"Page:{page} Page Size: {self.page_size} Query: " + data["query"])

            results = data["results"]

            logger.debug(f"Current results size: {len(results)} All Size: " + str(data["size"]))

            if results:
                yield results

            if len(results) < self.page_size:
                break

            page += 1

    def fofa_search_all(self, query, page=1):
        q_base64 = base64.b64encode(query.encode())
        params = {
            "qbase64": q_base64.decode('utf-8'),
            "page": page,
            "size": self.page_size,
            "fields": self.fields
        }
        data = self._api(self.search_all_path, params)
        return data

    def _api(self, path, params=None):
        if params is None:
            params = self.base_params
        else:
            params.update(self.base_params)

        url = self.base_url + path
        conn = utils.http_req(url, 'get', params=params)
        if conn.status_code != 200:
            raise Exception("{} http status code: {}".format(url, conn.status_code))

        data = conn.json()
        if data.get("error") and data["errmsg"]:
            raise Exception(data["errmsg"])

        return data


def fofa_query(query, fields="host,ip,port",
               page_size=Config.FOFA_PAGE_SIZE,
               max_page=Config.FOFA_MAX_PAGE):
    ret = []
    try:
        if not Config.FOFA_KEY:
            return "please set fofa key in config-docker.yaml"

        client = FofaClient(Config.FOFA_KEY,
                            page_size=page_size, max_page=max_page,
                            fields=fields)
        for results in client.search(query):
            ret.extend(results)

        logger.info(f"fofa query: {query} result size: {len(ret)}")
        return ret

    except Exception as e:
        error_msg = str(e)
        error_msg = error_msg.replace(Config.FOFA_KEY[10:], "***")
        if ret:
            logger.warning(f"fofa query error: {error_msg}")
            return ret
        return error_msg

