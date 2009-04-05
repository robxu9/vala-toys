namespace Gsc
{
	[CCode (instance_pos = -1)]
	public delegate bool CompletionFilterFunc (Gsc.Proposal proposal);
}
