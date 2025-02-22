import bz2
import gzip

cdef infer_compression(str filename, str mode='rt'):
    if filename.endswith('.gz'):
        return gzip.open(filename, mode)
    elif filename.endswith('.bz2') or filename.endswith('bzip2'):
        return bz2.open(filename, mode)
    return open(filename, mode)


cdef class File2:
    def __init__(self, str filename, str mode='rt', bint override=False):
        self.filename = filename
        self.mode = mode
        self.f = None

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        return False

    def __iter__(self):
        yield from self.f

    cpdef read(self):
        return self.f.read()

    cpdef readline(self):
        return self.f.readline()

    cpdef open(self):
        self.f = infer_compression(self.filename, self.mode)

    cpdef void close(self) except *:
        self.f.close()

    cpdef void write(self, data) except *:
        self.f.write(data)

    cpdef void writelines(self, lines) except *:
        self.f.writelines(lines)
