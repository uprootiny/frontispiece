defmodule Frontispiece.KernelTest do
  use ExUnit.Case, async: true

  alias Frontispiece.Kernel.{Practice, Episode, Well, Media, ContentLoader}
  alias Frontispiece.LLM.Router, as: LLMRouter

  describe "Practice" do
    test "changeset validates required fields" do
      changeset = Practice.changeset(%Practice{}, %{})
      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:name]
      assert {"can't be blank", _} = changeset.errors[:slug]
    end

    test "changeset accepts valid data" do
      changeset =
        Practice.changeset(%Practice{}, %{
          name: "Test Practice",
          slug: "test-practice",
          one_liner: "A test practice"
        })

      assert changeset.valid?
    end
  end

  describe "Episode" do
    test "changeset validates required fields" do
      changeset = Episode.changeset(%Episode{}, %{})
      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:title]
      assert {"can't be blank", _} = changeset.errors[:slug]
    end

    test "changeset accepts valid data" do
      changeset =
        Episode.changeset(%Episode{}, %{
          title: "Test",
          slug: "test",
          context: "testing",
          narration: "Some text"
        })

      assert changeset.valid?
    end
  end

  describe "Well" do
    test "changeset validates kind inclusion" do
      changeset = Well.changeset(%Well{}, %{kind: "invalid", label: "x", content: "y"})
      refute changeset.valid?
      assert {"is invalid", _} = changeset.errors[:kind]
    end

    test "changeset accepts all valid kinds" do
      for kind <- Well.kinds() do
        changeset = Well.changeset(%Well{}, %{kind: kind, label: "x", content: "y"})
        assert changeset.valid?, "expected #{kind} to be valid"
      end
    end
  end

  describe "Media" do
    test "changeset validates kind inclusion" do
      changeset = Media.changeset(%Media{}, %{kind: "invalid", path: "/x.png"})
      refute changeset.valid?
    end

    test "changeset accepts all valid kinds" do
      for kind <- Media.kinds() do
        changeset = Media.changeset(%Media{}, %{kind: kind, path: "/x.png"})
        assert changeset.valid?, "expected #{kind} to be valid"
      end
    end
  end

  describe "ContentLoader" do
    test "content_path returns a string" do
      path = ContentLoader.content_path()
      assert is_binary(path)
    end
  end

  describe "Router" do
    test "list_adapters returns all 4 adapters" do
      adapters = LLMRouter.list_adapters()
      assert length(adapters) == 4
      names = Enum.map(adapters, & &1.name)
      assert "claude" in names
      assert "codex" in names
      assert "coggy" in names
      assert "local" in names
    end

    test "run returns error for unknown adapter" do
      context = %{practice: "", episode: "", wells: [], history: []}

      assert {:error, :unknown_adapter} =
               LLMRouter.run("nonexistent", "hi", context)
    end

    test "adapter_names returns 4 names" do
      assert length(LLMRouter.adapter_names()) == 4
    end
  end
end
