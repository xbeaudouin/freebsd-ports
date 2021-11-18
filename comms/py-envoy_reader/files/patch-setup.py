--- setup.py.orig	2021-11-18 20:12:31 UTC
+++ setup.py
@@ -4,10 +4,6 @@ with open("README.md", "r") as fh:
     long_description = fh.read()
 
 
-setup_requirements = [
-    "pytest-runner>=5.2",
-]
-
 test_requirements = [
     "pytest-asyncio",
     "black>=19.10b0",
@@ -21,7 +17,6 @@ test_requirements = [
 ]
 
 dev_requirements = [
-    *setup_requirements,
     *test_requirements,
     "bump2version>=1.0.1",
     "coverage>=5.1",
@@ -38,7 +33,6 @@ dev_requirements = [
 requirements = ["httpx>=0.12.1", "envoy_utils>=0.0.1"]
 
 extra_requirements = {
-    "setup": setup_requirements,
     "test": test_requirements,
     "dev": dev_requirements,
     "all": [
@@ -57,9 +51,8 @@ setuptools.setup(
     long_description=long_description,
     long_description_content_type="text/markdown",
     url="https://github.com/jesserizzo/envoy_reader",
-    packages=setuptools.find_packages(),
+    packages=setuptools.find_packages(exclude=["tests","tests.*"]),
     install_requires=requirements,
-    setup_requires=setup_requirements,
     test_suite="tests",
     tests_require=test_requirements,
     extras_require=extra_requirements,
