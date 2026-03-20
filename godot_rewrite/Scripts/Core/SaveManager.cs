using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using Godot;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.Core;

public sealed class SaveManager
{
	private const int SlotCount = 3;

	private static readonly JsonSerializerOptions JsonOptions = new()
	{
		WriteIndented = true
	};

	public IEnumerable<int> EnumerateSlots()
	{
		for (var slot = 1; slot <= SlotCount; slot++)
		{
			yield return slot;
		}
	}

	public string GetSavePath(int slot)
	{
		return Path.Combine(ProjectSettings.GlobalizePath("user://"), $"save_{slot:00}.json");
	}

	public bool HasSave(int slot)
	{
		return File.Exists(GetSavePath(slot));
	}

	public void Save(GameState state, int slot)
	{
		Directory.CreateDirectory(ProjectSettings.GlobalizePath("user://"));
		var json = JsonSerializer.Serialize(state, JsonOptions);
		File.WriteAllText(GetSavePath(slot), json);
	}

	public GameState LoadOrCreate(int slot)
	{
		var path = GetSavePath(slot);
		if (!File.Exists(path))
		{
			return new GameState();
		}

		var json = File.ReadAllText(path);
		return JsonSerializer.Deserialize<GameState>(json) ?? new GameState();
	}

	public IReadOnlyList<SaveSlotSummary> GetSlotSummaries()
	{
		var result = new List<SaveSlotSummary>();
		foreach (var slot in EnumerateSlots())
		{
			var path = GetSavePath(slot);
			if (!File.Exists(path))
			{
				result.Add(new SaveSlotSummary(slot, false, TextDb.Ui("save.empty_title"), TextDb.Ui("save.empty_detail")));
				continue;
			}

			try
			{
				var state = LoadOrCreate(slot);
				var period = state.TimeSlot == 0 ? TextDb.Ui("common.daytime") : TextDb.Ui("common.nighttime");
				var title = TextDb.UiFormat("save.title_format", state.Day, period);
				var detail = TextDb.UiFormat("save.detail_format", state.Money, state.CurrentScene);
				result.Add(new SaveSlotSummary(slot, true, title, detail));
			}
			catch (Exception ex)
			{
				result.Add(new SaveSlotSummary(slot, true, TextDb.Ui("save.corrupt_title"), ex.Message));
			}
		}

		return result;
	}
}

public sealed record SaveSlotSummary(int Slot, bool Exists, string Title, string Detail);
