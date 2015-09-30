cat $SYBASE/$SYBASE_ASE/install/.log |grep Error > err_`date +%y%m%d`
cat err1_`date +%y%m%d` |grep -v "Error: 1608" > err_`date +%y%m%d`
rm err1_`date +%y%m%d`
cat $SYBASE/$SYBASE_ASE/install/_back.log |grep Error > err_back_`date +%y%m%d`
