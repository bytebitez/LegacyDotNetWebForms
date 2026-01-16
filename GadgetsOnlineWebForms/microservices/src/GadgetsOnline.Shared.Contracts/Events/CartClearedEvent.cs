namespace GadgetsOnline.Shared.Contracts.Events;

public class CartClearedEvent
{
    public string CartId { get; set; } = string.Empty;
    public DateTime ClearedAt { get; set; }
    public string Reason { get; set; } = string.Empty;
}
