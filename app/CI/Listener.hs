module CI.Listener where

import Control.Monad.State (get)
import Data.Bifunctor (first)
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8, encodeUtf8)
import qualified Network.Socket as N
import Sound.Osc as O
import Sound.Osc.Transport.Fd.Udp as O
import Zwirn.Language.Compiler
import Zwirn.Stream (sLocal)

type RemoteAddress = N.SockAddr

listenerStartMessage :: IO ()
listenerStartMessage = putStrLn "Listening for messages on port 2323"

listen :: Environment -> IO ()
listen env = recvMessageFrom (getUdp env) >>= act env >> listen env

recvMessageFrom :: O.Udp -> IO (Maybe Message, RemoteAddress)
recvMessageFrom udp = fmap (first packet_to_message) (recvFrom udp)

act :: Environment -> (Maybe O.Message, RemoteAddress) -> IO Environment
act env (Just (Message "/ping" []), remote) = putStrLn "ping" >> replyOk (getUdp env) remote >> return env
act env (Just (Message "/eval" [AsciiString stat]), remote) = do
  putStrLn $ "Evaluating: " ++ ascii_to_string stat
  x <- runCI env $ listenerCompiler (ascii_to_string stat)
  case x of
    Left (CIError err newEnv) -> replyEvalError (getUdp env) remote err >> return newEnv
    Right ("", newEnv) -> replyEvalOk (getUdp env) remote >> return newEnv
    Right (s, newEnv) -> replyEvalVal (getUdp env) remote s >> return newEnv
act env (Just m, remote) = replyError (getUdp env) remote ("Unhandeled Message: " ++ show m) >> return env
act env _ = return env

reply :: O.Udp -> RemoteAddress -> O.Packet -> IO ()
reply udp remote msg = O.sendTo udp msg remote

replyOk :: O.Udp -> RemoteAddress -> IO ()
replyOk udp = flip (reply udp) (O.p_message "/ok" [])

replyError :: O.Udp -> RemoteAddress -> String -> IO ()
replyError udp remote err = reply udp remote (O.p_message "/error" [utf8String err])

replyEvalVal :: O.Udp -> RemoteAddress -> String -> IO ()
replyEvalVal udp remote str = reply udp remote (O.p_message "/eval/value" [utf8String str])

replyEvalOk :: O.Udp -> RemoteAddress -> IO ()
replyEvalOk udp remote = reply udp remote (O.p_message "/eval/ok" [])

replyEvalError :: O.Udp -> RemoteAddress -> String -> IO ()
replyEvalError udp remote err = reply udp remote (O.p_message "/eval/error" [utf8String err])

utf8String :: String -> O.Datum
utf8String s = O.AsciiString $ encodeUtf8 $ T.pack s

toUTF8 :: O.Ascii -> String
toUTF8 x = T.unpack $ decodeUtf8 x

getUdp :: Environment -> O.Udp
getUdp = sLocal . tStream

listenerCompiler :: String -> CI (String, Environment)
listenerCompiler stat = do
  x <- compilerInterpreterBasic (T.pack stat)
  env <- get
  return (x, env)
