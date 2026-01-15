using Microsoft.EntityFrameworkCore;
using GadgetsOnline.Catalog.API.Models;

namespace GadgetsOnline.Catalog.API.Data;

public class CatalogDbContext : DbContext
{
    public CatalogDbContext(DbContextOptions<CatalogDbContext> options) : base(options) { }

    public DbSet<Product> Products { get; set; }
    public DbSet<Category> Categories { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Category>().HasData(
            new Category { CategoryId = 1, Name = "Mobile Phones", Description = "Latest collection of Mobile Phones" },
            new Category { CategoryId = 2, Name = "Laptops", Description = "Latest Laptops in 2022" },
            new Category { CategoryId = 3, Name = "Desktops", Description = "Latest Desktops in 2022" },
            new Category { CategoryId = 4, Name = "Audio", Description = "Latest audio devices" },
            new Category { CategoryId = 5, Name = "Accessories", Description = "USB Cables, Mobile chargers and Keyboards etc" }
        );

        modelBuilder.Entity<Product>().HasData(
            new Product { ProductId = 1, CategoryId = 1, Name = "Phone 12", Price = 699.00m, ProductArtUrl = "/Content/Images/Mobile/1.jpg" },
            new Product { ProductId = 2, CategoryId = 1, Name = "Phone 13 Pro", Price = 999.00m, ProductArtUrl = "/Content/Images/Mobile/2.jpg" },
            new Product { ProductId = 3, CategoryId = 1, Name = "Phone 13 Pro Max", Price = 1199.00m, ProductArtUrl = "/Content/Images/Mobile/3.jpg" },
            new Product { ProductId = 4, CategoryId = 2, Name = "XTS 13'", Price = 899.00m, ProductArtUrl = "/Content/Images/Laptop/1.jpg" },
            new Product { ProductId = 5, CategoryId = 2, Name = "PC 15.5'", Price = 479.00m, ProductArtUrl = "/Content/Images/Laptop/2.jpg" },
            new Product { ProductId = 6, CategoryId = 2, Name = "Notebook 14", Price = 169.00m, ProductArtUrl = "/Content/Images/Laptop/3.jpg" },
            new Product { ProductId = 7, CategoryId = 3, Name = "The IdeaCenter", Price = 539.00m, ProductArtUrl = "/Content/Images/placeholder.gif" },
            new Product { ProductId = 8, CategoryId = 3, Name = "COMP 22-df003w", Price = 389.00m, ProductArtUrl = "/Content/Images/placeholder.gif" },
            new Product { ProductId = 9, CategoryId = 4, Name = "Bluetooth Headphones Over Ear", Price = 28.00m, ProductArtUrl = "/Content/Images/Headphones/1.png" },
            new Product { ProductId = 10, CategoryId = 4, Name = "ZX Series", Price = 10.00m, ProductArtUrl = "/Content/Images/Headphones/2.png" },
            new Product { ProductId = 11, CategoryId = 5, Name = "Wireless charger", Price = 9.99m, ProductArtUrl = "/Content/Images/placeholder.gif" },
            new Product { ProductId = 12, CategoryId = 5, Name = "Mousepad", Price = 2.99m, ProductArtUrl = "/Content/Images/placeholder.gif" },
            new Product { ProductId = 13, CategoryId = 5, Name = "Keyboard", Price = 9.99m, ProductArtUrl = "/Content/Images/placeholder.gif" }
        );
    }
}
