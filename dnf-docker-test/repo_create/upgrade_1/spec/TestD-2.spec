Name:		TestD
Version:	1.0.0
Release:	2
Summary:	Richdeps test package

#Group:
License:	MIT
URL:		http://127.0.0.1/
Source0:	testdata.tar.gz
BuildArch:  noarch

#BuildRequires:

Requires:   TestE = 1.0.0-2


%description
Richdeps test package

%prep
%setup -q -n data/
%install
%files
%license
%doc
%changelog
