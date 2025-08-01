{
  lib,
  buildPythonPackage,
  fetchPypi,
  six,
  pythonOlder,
  scandir ? null,
  typing,
}:

buildPythonPackage rec {
  pname = "pathlib2";
  version = "2.3.7.post1";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-n+DtrYmLg8DD4ZnIQrJ+0hZkXS4Xd1ey3Wc4TUETxkE=";
  };

  propagatedBuildInputs = [
    six
  ]
  ++ lib.optionals (pythonOlder "3.5") [
    scandir
    typing
  ];

  meta = with lib; {
    description = "This module offers classes representing filesystem paths with semantics appropriate for different operating systems";
    homepage = "https://pypi.org/project/pathlib2/";
    license = with licenses; [ mit ];
    maintainers = [ ];
  };
}
