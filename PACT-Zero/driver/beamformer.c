#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/io.h>

#define DRIVER_NAME    "beamformer"
#define FPGA_BASE      0x40000000
#define FPGA_SIZE      0x1000
#define STEERING_AZIMUTH   0x00
#define STEERING_ELEVATION 0x04
#define PHASE_REG_0        0x08 //check the status reg valued (changed)
#define STATUS_REG         0x1C

/* For Continous Steering functionality
   add CMD register for continuous softcore steering
   Uncomment "%" lines to enable, remove "%" before uncommenting
   % #define CMD_REG 0x20
 */

static void __iomem *fpga_base;
static int major_num;

static ssize_t beamformer_write(struct file *f,
                                const char __user *buf,
                                size_t len, loff_t *off)
{
    int angles[2];
    if (copy_from_user(angles, buf, sizeof(angles)))
        return -EFAULT;
    iowrite32(angles[0], fpga_base + STEERING_AZIMUTH);
    iowrite32(angles[1], fpga_base + STEERING_ELEVATION);
    /* For Continous Steering functionality 
       also write to CMD_REG for PicoRV32 softcore
      % iowrite32(angles[0] | (angles[1] << 16), fpga_base + CMD_REG);
     */
    printk(KERN_INFO "Beamformer: az=%d el=%d\n", angles[0], angles[1]);
    return len;
}

static ssize_t beamformer_read(struct file *f,
                               char __user *buf,
                               size_t len, loff_t *off)
{
    int status = ioread32(fpga_base + STATUS_REG);
    if(copy_to_user(buf, &status, sizeof(int)))
        return -EFAULT;
    return sizeof(int);
}

static struct file_operations fops = {
    .owner = THIS_MODULE,
    .write = beamformer_write,
    .read  = beamformer_read,
};

static int __init beamformer_init(void)
{
    fpga_base = ioremap(FPGA_BASE, FPGA_SIZE);
    if(!fpga_base) {
        printk(KERN_ERR "Beamformer: ioremap failed\n");
        return -ENOMEM;
    }
    major_num = register_chrdev(0, DRIVER_NAME, &fops);
    if(major_num < 0) {
        iounmap(fpga_base);
        return major_num;
    }
    printk(KERN_INFO "Beamformer: loaded, major=%d\n", major_num);
    return 0;
}

static void __exit beamformer_exit(void)
{
    unregister_chrdev(major_num, DRIVER_NAME);
    iounmap(fpga_base);
    printk(KERN_INFO "Beamformer: unloaded\n");
}

module_init(beamformer_init);
module_exit(beamformer_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Aman");
MODULE_DESCRIPTION("PACT Zero Beamformer Driver");
