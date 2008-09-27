using GLib;

namespace Tests
{
 public class Foo
 {
  private string _prop = 1;

  public string prop { get { return _prop; } set { _prop = value; } }

  public string test_method (int i)
  {
    string result = "1";
    Bar bar = new Bar ();

    result = i.to_string ();
    bar.name = "a";
    return result;
  }
 }
}
