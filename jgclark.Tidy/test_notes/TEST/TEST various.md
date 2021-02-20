# TEST various
#ignore
Aim: leave this line alone

----
### Other types of task line markers
- [x] item 1 to complete and keep scheduling info @done(2020-08-01)
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
* [x] TEST todo done 1 #waiting @done(2020-09-07)
* [x] TEST todo done 2 #high @done(2020-09-07)
* [x] TEST todo done 3 #waiting #high  @done(2020-09-07)

### Testing done-check-off 
* [x] TEST todo without square brackets 1 #ztest @done(2020-09-07)
	* [x] TEST todo without square brackets 2 #ztest @done(2020-09-07)
* [x] TEST todo with square brackets 1 #ztest @done(2020-09-07)
	* [x] TEST todo with square brackets 2 #ztest @done(2020-09-07)

### Done AMPM testing
* [x] test 1 @done(2021-02-19 00:06)
* [x] test 2 @done(2020-08-03)
* [x] test 3 @done(2021-02-19 00:06)




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
