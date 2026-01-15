using Microsoft.EntityFrameworkCore;
using GadgetsOnline.Order.API.Models;

namespace GadgetsOnline.Order.API.Data;

public class OrderDbContext : DbContext
{
    public OrderDbContext(DbContextOptions<OrderDbContext> options) : base(options) { }

    public DbSet<Models.Order> Orders { get; set; }
    public DbSet<OrderDetail> OrderDetails { get; set; }
}
