defmodule GenAI.Provider.OpenAICompatibleProvidersTest do
  @moduledoc """
  Unit coverage for the OpenAI-compatible chat providers Z.AI (Zhipu GLM), Cerebras,
  and Qwen (Alibaba DashScope): config key, model -> provider/encoder wiring, and the
  chat-completions endpoint path (Z.AI overrides to /api/paas/v4/chat/completions;
  Cerebras uses the OpenAI default; Qwen uses DashScope compatible-mode /chat/completions).
  Deterministic — no network.
  """
  use ExUnit.Case, async: true

  alias GenAI.Provider.ZAI
  alias GenAI.Provider.Cerebras
  alias GenAI.Provider.Qwen

  describe "Z.AI" do
    test "config_key is :zai" do
      assert ZAI.config_key() == :zai
    end

    test "model/1 wires provider + encoder" do
      m = ZAI.Models.glm_4_6()
      assert m.model == "glm-4.6"
      assert m.provider == GenAI.Provider.ZAI
      assert m.encoder == GenAI.Provider.ZAI.Encoder
    end

    test "chat endpoint overrides to /api/paas/v4/chat/completions" do
      assert {:ok, {{:post, "https://api.z.ai/api/paas/v4/chat/completions"}, _}} =
               ZAI.Encoder.endpoint(nil, %{}, nil, nil, nil)
    end
  end

  describe "Cerebras" do
    test "config_key is :cerebras" do
      assert Cerebras.config_key() == :cerebras
    end

    test "model/1 wires provider + encoder" do
      m = Cerebras.Models.gpt_oss_120b()
      assert m.model == "gpt-oss-120b"
      assert m.provider == GenAI.Provider.Cerebras
      assert m.encoder == GenAI.Provider.Cerebras.Encoder
    end

    test "chat endpoint uses the OpenAI-default /v1/chat/completions" do
      assert {:ok, {{:post, "https://api.cerebras.ai/v1/chat/completions"}, _}} =
               Cerebras.Encoder.endpoint(nil, %{}, nil, nil, nil)
    end
  end

  describe "Qwen" do
    test "config_key is :qwen" do
      assert Qwen.config_key() == :qwen
    end

    test "model/1 wires provider + encoder" do
      m = Qwen.Models.qwen3_8_max()
      assert m.model == "qwen3.8-max"
      assert m.provider == GenAI.Provider.Qwen
      assert m.encoder == GenAI.Provider.Qwen.Encoder
    end

    test "quota-tab aliases wire expected ids" do
      assert Qwen.Models.qwen3_8_27b().model == "qwen3.8-27b"
      assert Qwen.Models.qwen3_8_2_4t_a95b().model == "qwen3.8-2.4t-a95b"
      assert Qwen.Models.qwen3_7_text_embedding().model == "qwen3.7-text-embedding"
      assert Qwen.Models.kimi_k3().model == "kimi-k3"
      assert Qwen.Models.qwen_image_3_0().model == "qwen-image-3.0"
      assert Qwen.Models.qwen_audio_3_0_asr_flash().model == "qwen-audio-3.0-asr-flash"

      assert Qwen.Models.qwen_audio_3_0_realtime_flash().model ==
               "qwen-audio-3.0-realtime-flash"

      assert Qwen.Models.qwen_audio_3_0_realtime_plus().model ==
               "qwen-audio-3.0-realtime-plus"
    end

    test "chat endpoint uses DashScope compatible-mode /chat/completions" do
      assert {:ok,
              {{:post, "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions"},
               _}} =
               Qwen.Encoder.endpoint(nil, %{}, nil, nil, nil)
    end

    test "native_base_url maps compatible-mode host to /api/v1" do
      assert Qwen.native_base_url() == "https://dashscope-intl.aliyuncs.com/api/v1"
    end
  end
end
