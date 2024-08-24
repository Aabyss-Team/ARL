import json


class BaseInfo:
    def __str__(self):
        return self.dump_json()

    def __repr__(self):
        return self.dump_json()

    def dump_json(self, flag = True):
        item = self._dump_json()
        if flag:
            return json.dumps(item)
        else:
            return item

    def _dump_json(self):
        raise NotImplementedError()