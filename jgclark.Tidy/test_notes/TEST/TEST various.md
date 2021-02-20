# TEST various
#ignore
Aim: leave this line alone

----
### Other types of task line markers
- [x] item 1 to complete and keep scheduling info @done(2020-08-01 12:34)
- [-] item 2 to cancel and keep scheduling info
- [x] open item @done(2021-01-08)
- task

- 

* 
### Testing >dates removal on completed/cancelled
* [x] silly old thing >2021-01-01
* [-] and this too >2021-02-02 can be removed

### Testing Delayed tasks removal
* [>] test for delayed and future task  >2020-07-06
* [>] test for delayed and overdue task >2020-07-04

### Testing tag removal
* [x] TEST todo done 1 #waiting
* [x] TEST todo done 2 #high high thing
* [x] TEST todo done 3 #waiting #high and more text

### Testing inbound date removal
* [x] TEST todo done <2020-09-07 with text
	* [x] TEST todo <2021-01-01

### Done AMPM testing
* [x] test 1 @done(2021-02-19 01:06PM)
* [x] test 2 @done(2020-08-03)
* [x] test 3 @done(2021-02-19 02:06AM)




### Archive testing
* Test comments for after a completed todo 
	> Comment line 1
	> Comment line 2
	- Other sort of line
	* [x] Closed sub-task @done(2020-08-22)
		- all these work OK, up until first open sub-task
		- [ ] Open sub-task
			- [ ] Open sub-sub-task
			> test comment
last line condition check
