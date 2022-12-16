
#include <iostream>  // fprintf
#include <fcntl.h>    // O_RDONLY
#include <unistd.h> // read,write

using namespace std;

#define MINIX_HEADER 32
#define GCC_HEADER 1024

void die(char const* str){
    cerr << str << endl;;
    exit(1);
}

void usage(void){
    die("Usage: build boot system [> image]");
}

int main(int argc, char** argv){
    if(3 != argc)
        usage();
    auto boot = argv[1];
    int fd = open(boot, O_RDONLY, 0);
    
    if(fd < 0)
        die("Unable to open 'boot'");

    char buf[1024]{};
    if(MINIX_HEADER != read(fd, buf, MINIX_HEADER))
        die("Unable to read header of 'boot'");
    long* header = (long*)buf;
    if(0x04100301 != header[0])
        die("Non-Minix header of 'boot'");
    if(MINIX_HEADER != header[1])
        die("Non-Minix header of 'boot'");
    if(header[3])
        die("Illegal data segment in 'boot'");
    if(header[4])
        die("Illegal bss segment in 'boot'");
    if(header[5])
        die("Non-Minix header of 'boot'");
    if(header[7])
        die("Illegal symbol table in 'boot'");
    
    auto len = read(fd, buf, sizeof buf);
    cerr << "Boot sector " << len << " bytes." << endl;
    if(512 < len)
        die("Boot block may not exceed 512 bytes");
    
    buf[510] = 0x55;
    buf[511] = 0xAA;
    len = write(1, buf, 512);
    if(512 != len)
        die("Write call failed");
    close(fd);

    auto system = argv[2];
    fd = open(system, O_RDONLY, 0);
    if(fd < 0)
        die("Unable to open 'systm'");
    if(GCC_HEADER != read(fd, buf, GCC_HEADER))
        die("Unable to read header of 'system'");
    if(header[5])
        die("Non-GCC header of 'syste'");
    int i = 0;
    for(; (len = read(fd, buf, sizeof buf)) > 0; i += len)
        if(len != write(1, buf, len))
            die("Write call failed");
    close(fd);
    cerr << "System " << i << " bytes. " << (i + 15) / 16 << endl;
    return 0;
}
