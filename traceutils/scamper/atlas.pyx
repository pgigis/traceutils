import ujson as json

from traceutils.file2.file2 cimport File2
from traceutils.scamper.hop cimport Hop, Trace, Reader


class AtlasErrorException(Exception):
    pass


cdef list create_hops(list hops):
    cdef list hopslist = []
    cdef dict h, result
    cdef list results
    cdef int i
    cdef AtlasHop hop
    if hops is not None:
        for i in range(len(hops)):
            h = hops[i]
            results = h.get('result')
            if not results:
                continue
            # print(h['result'])
            for result in h['result']:
                if 'from' in result:
                    hop = AtlasHop(hop=h['hop'], **result)
                    hopslist.append(hop)
                    break
    return hopslist


cdef class AtlasHop(Hop):
    def __init__(self, int hop=-1, double rtt=float('nan'), int size=-1, int ttl=-1, err=None, int itos=0, int ittl=1, str flags=None, dict icmpext=None, int late=0, int dup=0, str edst=None, list hdropts=None, **kwargs):
        cdef int icmp_type, icmp_code
        if err is None:
            icmp_type = 11
            icmp_code = 0
        else:
            icmp_type = 3
            if isinstance(err, str):
                if err == 'N':
                    icmp_code = 0
                elif err == 'H':
                    icmp_code = 1
                elif err == 'A':
                    icmp_code = 13
                elif err == 'P':
                    icmp_code = 2
                elif err == 'p':
                    icmp_code = 3
            elif isinstance(err, int):
                icmp_code = err
            else:
                raise AtlasErrorException('Unknown error code: {}'.format(err))
        self.addr = kwargs.get('from')
        self.probe_ttl = hop
        self.rtt = rtt
        self.reply_ttl = ttl
        self.reply_size = size
        self.icmp_type = icmp_type
        self.icmp_code = icmp_code
        self.icmpext = icmpext
        self.ismpls = bool(icmpext)
        self.reply_tos = itos
        self.icmp_q_ttl = ittl

        self.flags = flags
        self.late = late
        self.dup = dup
        self.edst = edst
        self.hdropts = hdropts


cdef class AtlasTrace(Trace):
    def __init__(self, int af=0, str dst_addr='', str dst_name='', long endtime=0, int fw=0, int group_id=0, int lts=0, int msm_id=0, str msm_name='', int paris_id=0, int prb_id=0, str proto='', list result=None, int size=0, str src_addr='', long timestamp=0, str type='', **kwargs):
        self.src = src_addr
        self.dst = dst_addr
        self.hops = create_hops(result)

        self.af = af
        self.dst_addr = dst_addr
        self.dst_name = dst_name
        self.endtime = endtime
        self.fw = fw
        self.group_id = group_id
        self.lts = lts
        self.msm_id = msm_id
        self.msm_name = msm_name
        self.paris_id = paris_id
        self.prb_id = prb_id
        self.proto = proto
        self.result = result
        self.size = size
        self.src_addr = src_addr
        self.timestamp = timestamp
        self.type = type


cdef class AtlasReader(Reader):
    def __init__(self, str filename):
        self.filename = filename
        self.f = None

    def __iter__(self):
        cdef str line
        cdef dict result
        for line in self.f:
            j = json.loads(line)
            # print(j)
            if isinstance(j, list):
                for result in j:
                    if result['type'] == 'traceroute':
                        yield AtlasTrace(**result)
            else:
                result = j
                if result['type'] == 'traceroute':
                    yield AtlasTrace(**result)

    cpdef void open(self) except *:
        self.f = File2(self.filename)
        self.f.open()

    cpdef void close(self) except *:
        self.f.close()
