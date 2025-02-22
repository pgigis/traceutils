from traceutils.utils.net cimport inet_pton_auto_str

from traceutils.radix.ip2as cimport IP2AS

cpdef ICMPType gettype(int family, int icmp_type, int icmp_code) except *:
    if family == AF_INET:
        if icmp_type == 0:
            return ICMPType.echo_reply
        elif icmp_type == 3:
            if icmp_code == 13:
                return ICMPType.spoofing
            else:
                return ICMPType.dest_unreach
        elif icmp_type == 8:
            return ICMPType.echo_request
        elif icmp_type == 11:
            return ICMPType.time_exceeded
    else:
        if icmp_type == 129:
            return ICMPType.echo_reply
        elif icmp_type == 1:
            if icmp_code == 5:
                return ICMPType.spoofing
            else:
                return ICMPType.dest_unreach
        elif icmp_type == 128:
            return ICMPType.echo_request
        elif icmp_type == 3:
            return ICMPType.time_exceeded

cdef class Hop:

    def __init__(self, str addr, unsigned char probe_ttl, double rtt, unsigned char reply_ttl, int reply_tos, int reply_size, unsigned char icmp_type, unsigned char icmp_code, unsigned char icmp_q_ttl, int icmp_q_tos, int family):
        self.addr = addr
        self.probe_ttl = probe_ttl
        self.rtt = rtt
        self.reply_ttl = reply_ttl
        self.reply_tos = reply_tos
        self.reply_size = reply_size
        self.icmp_type = icmp_type
        self.icmp_code = icmp_code
        self.icmp_q_ttl = icmp_q_ttl
        self.icmp_q_tos = icmp_q_tos
        self.family = family

    def __repr__(self):
        return '{ttl:02d}: {addr}'.format(addr=self.addr, ttl=self.probe_ttl)

    cpdef bytes set_packed(self):
        self.packed = inet_pton_auto_str(self.addr)
        return self.packed


cdef class Trace:

    def __init__(self, str src, str dst, list hops):
        self.src = src
        self.dst = dst
        self.hops = hops
        self.loop = None
        self.family = 0

    def __repr__(self):
        return '\n'.join(repr(hop) for hop in self.hops)

    cpdef list addrs(self):
        cdef Hop h
        return [h.addr for h in self.hops]

    cpdef void prune_dups(self) except *:
        cdef str prev = None, haddr
        cdef list hops = []
        # cdef int i
        cdef Hop hop
        # for i in range(len(self.hops)):
        #     hop = self.hops[i]
        for hop in self.hops:
            haddr = hop.addr
            if haddr != prev:
                hops.append(hop)
                prev = haddr
            else:
                hops[-1] = hop
        self.hops = hops

    cpdef void prune_loops(self) except *:
        cdef set seen = set()
        cdef int end = len(self.hops), i
        cdef str addr, prev
        prev = None
        for i in range(len(self.hops) - 1, -1, -1):
            addr = self.hops[i].addr
            if addr in seen and addr != prev:
                end = i
            else:
                seen.add(addr)
            prev = addr
        if end < len(self.hops):
            self.loop = self.hops[end:]
            self.hops = self.hops[:end+1]

    cpdef void prune_private(self, IP2AS ip2as) except *:
        cdef Hop h
        self.hops = [h for h in self.hops if ip2as[h.addr] != -1]

    cpdef void set_packed(self) except *:
        for hop in self.hops:
            hop.set_packed()


cdef class Reader:

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        return False

    cpdef void open(self) except *:
        raise NotImplementedError()

    cpdef void close(self) except *:
        raise NotImplementedError()
