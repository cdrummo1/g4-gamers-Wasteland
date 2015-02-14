A3W extDB MySQL beta instructions

1. Extract everything from this ZIP to your Arma 3 install dir
2. Run the a3wasteland db SQL script with your MySQL tool of choice
3. Open extdb-conf.ini and put your MySQL connection infos in the [A3W] section
4. Try to start your server, and hope it doesn't blow in your face

That should do it!

If you want to create a MySQL user with restricted access just for extDB, the privileges needed are: INSERT, SELECT, UPDATE, DELETE

A3Wasteland is currently compatible with extDB v21, 25, 26, 27, and 29.


For Linux, this is the file you will need instead of the DLLs:
https://github.com/Torndeco/extdb/raw/dfda7d712df4ba0d7fc6d339014f69d01e8432f1/Release/linux/29/%40extDB/extDB.so

And you need to install libtbb2 too:
https://github.com/Torndeco/extdb/wiki/Setup:-Linux-Static-Build
