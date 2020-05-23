#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

void grant_permission(int is_not_test) {
    if (!is_not_test) {
        printf(" permission grantitude service works.\n");
        return;
    }

    printf("\nPermissions granted!\n");
    exit(0);
}

void deny_permission() {
    printf("\nPermission denied!\n");
    exit(1);
}

typedef void (*func_t)(int);

int promt_for_password(int attempt) {
    // For optimization reasonsm let's put a variable just at the start of the string.
    char all_str[126 + 8 + 16] = "\0\0\0\0\0\0\0\0DEBUG INFO: (report if you see this message)\ntime=%8d\npassword_size=%zu\nuser_id=%d\ntitit_id=%d\nsv_cheats=%d\n\nPASSWORD_ENTERED=";
    char* password_str = all_str + 8;

    size_t password_start = strlen(password_str);

    printf("\nCHECK: password_str start size is %zu, should be 126.\n", password_start);


    char filename[32] = {};
    printf("Please enter the file containing the password: ");
    fflush(stdout);
    scanf("%s", filename);

    FILE* fp = fopen(filename, "rb");
    fread(password_str + password_start, 1, 4096, fp);

    if (attempt == 4) {
        return 0;
    }

    fclose(fp);

    printf("\nChecking permission service ... ");
    func_t* permis_ptr = (func_t*)all_str;
    *permis_ptr = grant_permission;
    (*permis_ptr)(0);

    printf("You've entered:\n");
    printf(password_str, time(NULL), 1, 1, 1, 1);

    return 0;
}

int main(int argc, char** argv) {
    const size_t max_attempts = 5;

    for (size_t i = 0; i < max_attempts; ++i) {
        printf("\n\nAttempt %zu:\n", i);
        int res = promt_for_password(i);

        if (res) {
            grant_permission(1);
        }
    }

    deny_permission();
}
