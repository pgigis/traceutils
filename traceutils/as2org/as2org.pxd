from traceutils.utils.dicts cimport StrDict, EmptyDict

cdef class AS2Org:
    cdef StrDict orgs
    cdef StrDict asn_names
    cdef StrDict asn_org_names
    cdef readonly EmptyDict siblings

    cpdef str name(self, int asn);
    cpdef str asn_name(self, int asn);