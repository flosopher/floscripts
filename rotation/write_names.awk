#!/usr/bin/awk -f

BEGIN{
  count=0;
}


!/^HETATM/ && !/^END/{ print $0;}   #print out whole line, for every non hetatm line

/^HETATM/ { 
  het[count++]=$0;
}

END{
  if(headfile=="") {
    for(i=0;i<count;i++)
    print het[i];
  } else {
    count=0;
    while ((getline line < headfile )>0) {
      if( substr(line,13,1)!="V")print substr(line,1,30) substr(het[count++],31,60) ;
      else print line;
    }
  }
  print "END";
}
							   
