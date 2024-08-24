

class WihRecord:
    def __init__(self, record_type, content, source, site, fnv_hash):
        self.recordType = record_type
        self.content = content
        self.source = source
        self.site = site
        self.fnv_hash = fnv_hash

    def __str__(self):
        return "{} {} {} {}".format(self.recordType, self.content, self.source, self.site)

    def __repr__(self):
        return "<WihRecord>" + self.__str__()

    def __eq__(self, other):
        return self.fnv_hash == other.fnv_hash

    def __hash__(self):
        return self.fnv_hash

    def dump_json(self):
        return {
            "record_type": self.recordType,
            "content": self.content,
            "site": self.site,
            "source": self.source,
            "fnv_hash": str(self.fnv_hash),
        }