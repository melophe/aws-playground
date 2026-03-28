import express from "express";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const app = express();
const ssm = new SSMClient({ region: "ap-northeast-1" });
const __dirname = dirname(fileURLToPath(import.meta.url));

async function getParameter(name) {
  const res = await ssm.send(
    new GetParameterCommand({ Name: name, WithDecryption: true })
  );
  return res.Parameter.Value;
}

// Parameter Storeから設定を取得してフロントに渡す
app.get("/config", async (req, res) => {
  try {
    const [userPoolId, clientId] = await Promise.all([
      getParameter("/cognito-handson/user-pool-id"),
      getParameter("/cognito-handson/client-id"),
    ]);
    res.json({ userPoolId, clientId });
  } catch (err) {
    console.error("Parameter Store取得エラー:", err.message);
    res.status(500).json({ error: "設定の取得に失敗しました" });
  }
});

// 静的ファイル配信
app.use(express.static(join(__dirname, "public")));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`http://localhost:${PORT}`);
});
