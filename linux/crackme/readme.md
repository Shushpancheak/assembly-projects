# crackme

## Task:
Create an executable that promts a user to enter a password. Depending on the correctness of the password, the user will reacieve a message "permission granted/denied".

## Realization:
## Legend:
You have been given a debug build of a server that permits user to proceed only if they specify a file that contains the right password. Can you manage to get permission without knowing the actual password? Note that the build was built using `-fPIE` key, which implies that the executable is affected by `ASLR`, meaning that offsets of functions are chosen randomly at the startup time.
