using Microsoft.EntityFrameworkCore;
using GadgetsOnline.Cart.API.Models;

namespace GadgetsOnline.Cart.API.Data;

public class CartDbContext : DbContext
{
    public CartDbContext(DbContextOptions<CartDbContext> options) : base(options) { }

    public DbSet<CartItem> CartItems { get; set; }
}
