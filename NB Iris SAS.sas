/* Credit: https://www.lexjansen.com/nesug/nesug04/po/po09.pdf */


/* Load dataset */
proc sql;
    create table iris as
    select *
    from sashelp.iris;
quit;

/* Display the first few rows of the iris dataset */
proc print data=iris (obs=10);
run;


/* Convert species to binary class: setosa vs. others */
data iris;
    set iris;
    if Species = "Setosa" then Target = 1;
    else Target = 0;
    drop Species;
run;

/* Display the first few rows of the iris dataset */
proc print data=iris (obs=10);
run;

/* Split dataset into training and testing sets */
data train_data test_data;
    set iris;
    if mod(_N_, 3) = 0 then output test_data;
    else output train_data;
run;

%macro NB(train=,score=,nclass=,target=,inputs=); 
	%let error=0; 
	%if %length(&train) = 0 %then %do; 
		%put ERROR: Value for macro parameter TRAIN is missing ; 
		%let error=1; 
	%end; 
	%if %length(&score) = 0 %then %do;
		%put ERROR: Value for macro parameter SCORE is missing ;
		%let error=1; 
	%end; 
	%if %length(&nclass) = 0 %then %do;
		%put ERROR: Value for macro parameter NCLASS is missing ; 
		%let error=1; 
	%end; 
	%if %length(&target) = 0 %then %do;
		%put ERROR: Value for macro parameter TARGET is missing ; 
		%let error=1; 
	%end; 
	%if %length(&inputs) = 0 %then %do; 
		%put ERROR: Value for macro parameter INPUTS is missing ; 
		%let error=1; 
	%end; 
	%if &error=1 %then %goto finish; 
	%if %sysfunc(exist(&train)) = 0 %then %do; 
		%put ERROR: data set &train does not exist ; 
		%let error=1; 
	%end; 
	%if %sysfunc(exist(&score)) = 0 %then %do; 
		%put ERROR: data set &score does not exist ; 
		%let error=1; 
	%end; 
	%if &error=1 %then %goto finish;
	%LET nvar=0; 
	%do %while (%length(%scan(&inputs,&nvar+1))>0); 
		%LET nvar=%eval(&nvar+1); 
	%end; 
	proc freq data=&train noprint; 
		tables &target / out=_priors_ ; 
		run; 
	%do k=1 %to &nclass;
	proc sql noprint; 
		select percent, count into :Prior&k, :Count&k 
		from _priors_ 
		where &target=&k; 
		quit; 
	%end k; 
	%do i=1 %to &nvar; 
		%LET var=%scan(&inputs,&i); 
		%do j=1 %to &nclass; 
			proc freq data=&train noprint; 
				tables &var / out=_&var.&j (drop=count) missing;
				where &target=&j;    
				run; 
		%end j; 
		data _&var ; 
			merge %do k=1 %to &nclass; 
					_&var.&k (rename=(percent=percent&k)) 
				%end; ; 
			by &var;
			%do k=1 %to &nclass; if percent&k=. then percent&k=0; %end; 
		run; 
		proc sql; 
			create table &score AS 
			select a.* 
				%do k=1 %to &nclass; 
				, b.percent&k as percent&K._&var       
				%end;
			from &score as a left join _&var as b 
			on a.&var=b.&var; 
			quit; 
	%end i; 
	data &score (drop=L product maxprob 
					%do i=1 %to &nclass; percent&i._: %end;); 
		set &score; 
		maxprob=0; 
		%do k=1 %to &nclass; 
			array vars&k (&Nvar) 
			%do i=1 %to &nvar; percent&K._%scan(&inputs,&i) %end; ; 
			product=log(&&Prior&k); 
			do L=1 to &nvar;    
				if vars&k(L)>0 then product=product+log(vars&k(L)); else    
				product=product+log(0.5)-log(&&count&k); 
			end; 
			if product>maxprob then do; maxprob=product; _class_=&k; end; 
		%end k; 
	run; 
	%finish: ; 
%mend NB; 

/* Call NB macro for Naive Bayes classification */
%NB(
    train=train_data,
    score=test_data,
    nclass=2,
    target=Target,
    inputs=SepalLength SepalWidth PetalLength PetalWidth
);

