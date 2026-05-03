% readtext.m read in a text document and translate to character string
[fid,messagei] = fopen('OZ.txt','r');  % file must be in text format
fdata=fread(fid)';                     % read text as a vector
text=char(fdata);                      % change to a character string
