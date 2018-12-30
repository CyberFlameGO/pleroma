# Pleroma: A lightweight social networking server
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Object do
  use Ecto.Schema
  alias Pleroma.{Repo, Object, User, Activity, HTML}
  import Ecto.{Query, Changeset}

  schema "objects" do
    field(:data, :map)

    timestamps()
  end

  def create(data) do
    Object.change(%Object{}, %{data: data})
    |> Repo.insert()
  end

  def change(struct, params \\ %{}) do
    struct
    |> cast(params, [:data])
    |> validate_required([:data])
    |> unique_constraint(:ap_id, name: :objects_unique_apid_index)
  end

  def get_by_ap_id(nil), do: nil

  def get_by_ap_id(ap_id) do
    Repo.one(from(object in Object, where: fragment("(?)->>'id' = ?", object.data, ^ap_id)))
  end

  def normalize(obj) when is_map(obj), do: Object.get_by_ap_id(obj["id"])
  def normalize(ap_id) when is_binary(ap_id), do: Object.get_by_ap_id(ap_id)
  def normalize(_), do: nil

  # Owned objects can only be mutated by their owner
  def authorize_mutation(%Object{data: %{"actor" => actor}}, %User{ap_id: ap_id}),
    do: actor == ap_id

  # Legacy objects can be mutated by anybody
  def authorize_mutation(%Object{}, %User{}), do: true

  if Mix.env() == :test do
    def get_cached_by_ap_id(ap_id) do
      get_by_ap_id(ap_id)
    end
  else
    def get_cached_by_ap_id(ap_id) do
      key = "object:#{ap_id}"

      Cachex.fetch!(:object_cache, key, fn _ ->
        object = get_by_ap_id(ap_id)

        if object do
          {:commit, object}
        else
          {:ignore, object}
        end
      end)
    end
  end

  def context_mapping(context) do
    Object.change(%Object{}, %{data: %{"id" => context}})
  end

  def delete(%Object{data: %{"id" => id}} = object) do
    with Repo.delete(object),
         Repo.delete_all(Activity.all_non_create_by_object_ap_id_q(id)),
         {:ok, true} <- Cachex.del(:object_cache, "object:#{id}") do
      {:ok, object}
    end
  end

  def get_cached_scrubbed_html(content, scrubbers, object) do
    key = "#{generate_scrubber_signature(scrubbers)}|#{object.id}"
    Cachex.fetch!(:scrubber_cache, key, fn _key -> ensure_scrubbed_html(content, scrubbers) end)
  end

  def get_cached_stripped_html(content, object) do
    get_cached_scrubbed_html(content, HtmlSanitizeEx.Scrubber.StripTags, object)
  end

  def ensure_scrubbed_html(
        content,
        scrubbers
      ) do
    {:commit, HTML.filter_tags(content, scrubbers)}
  end

  defp generate_scrubber_signature(scrubber) when is_atom(scrubber) do
    generate_scrubber_signature([scrubber])
  end

  defp generate_scrubber_signature(scrubbers) do
    Enum.reduce(scrubbers, "", fn scrubber, signature ->
      # If a scrubber does not have a version(e.g HtmlSanitizeEx.Scrubber.StripTags) it is assumed it is always 0)
      version =
        if Kernel.function_exported?(scrubber, :version, 0) do
          scrubber.version
        else
          0
        end

      "#{signature}#{to_string(scrubber)}#{version}"
    end)
  end
end
