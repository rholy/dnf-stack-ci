%undefine _debuginfo_subpackages

Name:           nodejs
Epoch:          1
Version:        8.11.4
Release:        1.module_2030+42747d40

License:        MIT and ASL 2.0 and ISC and BSD
URL:            http://nodejs.org/

Summary:        JavaScript runtime

Provides:       nodejs = 1:8.11.4-1.module_2030+42747d40
Provides:       nodejs(x86-64) = 1:8.11.4-1.module_2030+42747d40
Provides:       bundled(c-ares) = 1.10.1
Provides:       bundled(icu) = 60.1
Provides:       bundled(v8) = 6.2.414.54
Provides:       nodejs(abi) = 8.11
Provides:       nodejs(abi8) = 8.11
Provides:       nodejs(engine) = 8.11.4
Provides:       nodejs(v8-abi) = 6.2
Provides:       nodejs(v8-abi6) = 6.2
Provides:       nodejs-punycode = 2.0.0
Provides:       npm(punycode) = 2.0.0

Requires:       rtld(GNU_HASH)

Conflicts:      node <= 0.3.2-12

Recommends:     npm = 1:5.6.0-1.8.11.4.1.module_2030+42747d40

%description
Node.js is a platform built on Chrome's JavaScript runtime
for easily building fast, scalable network applications.
Node.js uses an event-driven, non-blocking I/O model that
makes it lightweight and efficient, perfect for data-intensive
real-time applications that run across distributed devices.

%package devel
Summary:        JavaScript runtime - development headers

Provides:       nodejs-devel = 1:8.11.4-1.module_2030+42747d40
Provides:       nodejs-devel(x86-64) = 1:8.11.4-1.module_2030+42747d40

Requires:       rtld(GNU_HASH)
Requires:       nodejs(x86-64) = 1:8.11.4-1.module_2030+42747d40

%description devel
Development headers for the Node.js JavaScript runtime.

%package docs
Summary:        Node.js API documentation
BuildArch:      noarch

Provides:       nodejs-docs = 1:8.11.4-1.module_2030+42747d40

Conflicts:      nodejs < 1:8.11.4-1.module_2030+42747d40
Conflicts:      nodejs > 1:8.11.4-1.module_2030+42747d40

%description docs
The API documentation for the Node.js JavaScript runtime.

%files

%files devel

%files docs

%changelog
