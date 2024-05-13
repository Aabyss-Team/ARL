from app.services.dns_query import DNSQueryBase
from app import utils



class Query(DNSQueryBase):
    def __init__(self):
        super(Query, self).__init__()
        self.source_name = "chaos"
        self.api_url = "https://dns.projectdiscovery.io/"
        self.api_key = None

    def init_key(self, api_key=None):
        self.api_key = api_key

    def sub_domains(self, target):
        headers = {
            "Authorization": self.api_key
        }
        results = []
        url = "{}dns/{}/subdomains".format(self.api_url, target)
        items = utils.http_req(url, 'get', headers=headers).json()
        for name in items["subdomains"]:
            subdoamin = name + "." + target
            results.append(subdoamin)

        return list(set(results))
