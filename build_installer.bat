
:: Builds the installer for DSVE. Requires OCRA and Inno Setup.

:: The gem version of OCRA won't work, it's missing the most recent few commits which fix building the Inno Setup file.
:: Instead you need to use the latest version of OCRA from the source: https://github.com/larsch/ocra/tree/2e7c88fd6ac7ae5f881d838dedd7ad437bda018b
:: The easiest way to do this is to install the latest gem version of OCRA, then go to the folder where OCRA was installed in your Ruby installation and replace the file /bin/ocra with the /bin/ocra from the source.

ocra gui.rb --output dsve.exe --no-lzma --chdir-first --innosetup setup.iss
